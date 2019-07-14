# frozen_string_literal: true

class ShafClient
  module Cache
    class Entry
      attr_reader :key, :payload, :etag, :expire_at

      class << self
        def from(env)
          response_headers = response_headers(env)
          new(
            key: key(env),
            payload: env[:body],
            etag: response_headers[:etag],
            expire_at: expire_at(response_headers),
            vary: vary(response_headers)
          )
        end

        private

        def key(env)
          uri = env.fetch(:url)
          query = (uri.query || '').split('&').sort.join('&')
          [uri.host, uri.path, query].join('_').to_sym
        end

        def response_headers(env)
          response_headers = env.response_headers
          response_headers ||= {}
          response_headers.transform_keys { |k| k.downcase.to_sym }
        end

        # def request_headers(env)
        #   request_headers = env.request_headers
        #   request_headers ||= env.request_headers
        #   request_headers ||= {}
        #   request_headers.transform_keys { |k| k.downcase.to_sym }
        # end

        def expire_at(headers)
          cache_control = headers[:'cache-control']
          return unless cache_control

          max_age = cache_control[/\bmax-age=(\d+)/, 1]
          Time.now + max_age.to_i if max_age
        end

        def vary(headers)
          keys = headers.fetch(:vary, '').split(',')
          keys.each_with_object({}) do |key, vary|
            key = key.strip.downcase.to_sym
            vary[key] = headers[key]
          end
        end
      end

      def initialize(key:, payload:, etag: nil, expire_at: nil, vary: {})
        @key = key.freeze
        @payload = payload.freeze
        @etag = etag.freeze
        @expire_at = expire_at.freeze
        @vary = vary.freeze
        freeze
      end

      def expired?
        not fresh?
      end

      def fresh?
        expire_at && expire_at >= Time.now
      end

      def valid?(check_expiration: true)
        return false unless payload?
        return true unless check_expiration
        fresh?
      end

      def payload?
        payload && !payload.empty?
      end

      def storable?
        return false unless payload?
        etag || expire_at
      end
    end
  end
end
