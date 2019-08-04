# frozen_string_literal: true

class ShafClient
  module Middleware
    class HttpCache
      class Query
        extend Key

        attr_reader :key, :headers

        def self.from(env)
          return from_entry(env) if env.is_a? Entry

          new(
            key: key(env.fetch(:url)),
            headers: env.request_headers.transform_keys { |k| k.downcase.to_sym }
          )
        end

        def self.from_entry(entry)
          new(
            key: entry.key,
            headers: entry.vary
          )
        end

        def initialize(key:, headers: {})
          @key = key
          @headers = headers
        end

        def match?(vary)
          vary.all? do |key, value|
            headers[key] == value
          end
        end
      end
    end
  end
end
