# frozen_string_literal: true

class ShafClient
  module Middleware
    class HttpCache
      class EnvBuilder
        def self.build(
          method: :get,
          body: 'body',
          url: 'https://some_host.com/some_resource',
          request: nil,
          request_headers: {},
          ssl: nil,
          parallel_manager: nil,
          params: nil,
          response: nil,
          response_headers: {},
          status: nil
        )
          Faraday::Env.new(
            method,
            body,
            URI(url),
            request,
            request_headers,
            ssl,
            parallel_manager,
            params,
            response,
            response_headers,
            status
          )
        end
      end
    end
  end
end
