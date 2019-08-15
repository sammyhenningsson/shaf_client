# frozen_string_literal: true

require 'time'
require 'shaf_client/middleware/http_cache/key'

class ShafClient
  module Middleware
    class HttpCache
      class Entry
        extend Key

        attr_reader :key, :payload, :etag, :vary, :response_headers
        attr_accessor :expire_at

        class << self
          def from(env)
            response_headers = response_headers(env)

            new(
              key: key(env.fetch(:url)),
              payload: env[:body],
              etag: response_headers[:etag],
              expire_at: expire_at(response_headers),
              vary: vary(env),
              response_headers: response_headers
            )
          end

          private

          def response_headers(env)
            response_headers = env.response_headers
            response_headers ||= {}
            response_headers.transform_keys { |k| k.downcase.to_sym }
          end

          def request_headers(env)
            request_headers = env.request_headers
            request_headers ||= {}
            request_headers.transform_keys { |k| k.downcase.to_sym }
          end

          def expire_at(headers)
            cache_control = headers[:'cache-control']
            return unless cache_control

            max_age = cache_control[/\bmax-age=(\d+)/, 1]
            Time.now + max_age.to_i if max_age
          end

          def vary(env)
            response_headers = response_headers(env)
            request_headers  = request_headers(env)
            keys = response_headers.fetch(:vary, '').split(',')
            keys.each_with_object({}) do |key, vary|
              key = key.strip.downcase.to_sym
              # The respose that we see is already decoded (e.g. gunzipped) so
              # we shouldn't need to care about the Accept-Encoding header
              next if key == :'accept-encoding'
              vary[key] = request_headers[key]
            end
          end
        end

        def initialize(key:, payload: nil, etag: nil, expire_at: nil, vary: {}, response_headers: {})
          expire_at = Time.parse(expire_at) if expire_at.is_a? String
          @key = key.freeze
          @payload = payload.freeze
          @etag = etag.freeze
          @expire_at = expire_at.freeze
          @vary = vary.freeze
          @response_headers = response_headers
          freeze
        end

        def expired?
          not fresh?
        end

        def fresh?
          !!(expire_at && expire_at >= Time.now)
        end

        def valid?
          return false unless payload?
          fresh?
        end

        def invalid?
          !valid?
        end

        def payload?
          !!(payload && !payload.empty?)
        end

        def storable?
          return false unless payload?
          !!(etag || expire_at)
        end
      end
    end
  end
end
