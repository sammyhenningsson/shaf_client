# FIXME zip payload

class ShafClient
  module Middleware
    class Cache
      module Control
      end

      def initialize(app)
        @app = app
        @cache = {}
      end

      def call(request_env)
        uri = request_env[:url]

        if request_env[:method] == :get
          cached = get(uri: uri)
          return cached if cached # FIXME: return a Faraday response
        end

        add_etag(request_env)

        @app.call(request_env).on_complete do |response_env|
          cache_response(uri, response_env)
        end
      end

      def add_etag(env)
        etag = get_etag(uri: env[:url])
        env[:request_headers]['Etag'] = etag if etag
      end

      def cache_response(uri, response_env)
        etag = response_env[:response_headers]['etag']
        cache_control = response_env[:response_headers]['cache-control']
        expire_at = expiration(cache_control)
        store(
          uri: uri,
          payload: response_env[:body],
          etag: etag,
          expire_at: expire_at
        )
      end

      def expiration(cache_control)
        return unless cache_control

        max_age = cache_control[/max-age=\s?(\d+)/, 1]
        Time.now + max_age.to_i if max_age
      end

      def get(uri:)
        entry = @cache[uri.to_s]
        return entry[:payload] if valid? entry
        yield if block_given?
      end

      def get_etag(uri:)
        @cache.dig(uri.to_s, :etag)
      end

      def store(uri:, payload:, etag: nil, expire_at: nil)
        return unless payload && uri && (etag || expire_at)

        @cache[uri.to_s] = {
          payload: payload,
          etag: etag,
          expire_at: expire_at
        }
      end

      def valid?(entry)
        return false unless entry
        return false unless entry[:payload]
        entry[:expire_at] && entry[:expire_at] > Time.now
      end
    end
  end
end
