# FIXME zip payload

class ShafClient
  module Middleware
    class Cache
      DEFAULT_THRESHOLD = 10_000

      Response = Struct.new(:status, :body, :headers, keyword_init: true)

      module Control
        def cache_size
          Cache.size
        end

        def clear_cache
          Cache.clear
        end

        def clear_stale_cache
          Cache.clear_stale
        end
      end

      class << self
        attr_writer :threshold

        def inc_request_count
          @request_count ||= 0
          @request_count += 1
          return if (@request_count % 500 != 0)
          clear_stale
          check_threshold
        end

        def size
          cache.size
        end

        def clear
          mutex.synchronize do
            @cache = {}
          end
        end

        def clear_stale
          mutex.synchronize do
            cache.delete_if { |_key, entry| expired? entry }
          end
        end

        def get(key:, check_expiration: true)
          entry = nil
          mutex.synchronize do
            entry = cache[key.to_sym].dup
          end
          return entry[:payload] if valid?(entry, check_expiration)
          yield if block_given?
        end

        def get_etag(key:)
          mutex.synchronize do
            cache.dig(key.to_sym, :etag)
          end
        end

        def store(key:, payload:, etag: nil, expire_at: nil)
          return unless payload && key && (etag || expire_at)

          mutex.synchronize do
            cache[key.to_sym] = {
              payload: payload,
              etag: etag,
              expire_at: expire_at
            }
          end
        end

        def threshold
          @threshold ||= DEFAULT_THRESHOLD
        end

        private

        def mutex
          @mutex = Mutex.new
        end

        def cache
          mutex.synchronize do
            @cache ||= {}
          end
        end

        def valid?(entry, check_expiration = true)
          return false unless entry
          return false unless entry[:payload]
          return true unless check_expiration
          !expired? entry
        end

        def expired?(entry)
          return true unless entry[:expire_at]
          entry[:expire_at] < Time.now
        end

        def check_threshold
          return if size < threshold

          count = 500
          cache.each do |key, _value|
            break if count <= 0
            cache[key] = nil
            count -= 1
          end
          cache.compact!
        end
      end

      def initialize(app, **options)
        @app = app
        @options = options
      end

      def call(request_env)
        key = cache_key(request_env)

        skip_cache = request_env[:request_headers].delete :skip_cache

        if !skip_cache && request_env[:method] == :get
          cached = self.class.get(key: key)
          return Response.new(body: cached, headers: {}) if cached
        end

        add_etag(request_env, key)

        @app.call(request_env).on_complete do |response_env|
          # key might have changed in other middleware
          key = cache_key(response_env)
          add_cached_payload(response_env, key)
          cache_response(response_env, key)
          self.class.inc_request_count
        end
      end

      def add_etag(env, key = nil)
        return unless %i[get head].include? env[:method]
        key ||= cache_key(env)
        etag = self.class.get_etag(key: key)
        env[:request_headers]['If-None-Match'] = etag if etag
      end

      def add_cached_payload(response_env, key)
        return if response_env[:status] != 304
        cached = self.class.get(key: key, check_expiration: false)
        response_env[:body] = cached if cached
      end

      def cache_response(response_env, key)
        etag = response_env[:response_headers]['etag']
        cache_control = response_env[:response_headers]['cache-control']
        expire_at = expiration(cache_control)
        self.class.store(
          key: key,
          payload: response_env[:body],
          etag: etag,
          expire_at: expire_at
        )
      end

      def cache_key(env)
        :"#{env[:url]}.#{env[:request_headers][auth_header]}"
      end

      def auth_header
        @options.fetch(:auth_header, 'X-AUTH-TOKEN')
      end

      def expiration(cache_control)
        return unless cache_control

        max_age = cache_control[/max-age=\s?(\d+)/, 1]
        Time.now + max_age.to_i if max_age
      end
    end
  end
end
