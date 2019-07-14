# frozen_string_literal: true

require 'spec_helper'

class ShafClient
  module Cache
    describe Entry do
      def build_env(
        method: :get,
        body: "body",
        url: "https://some_host.com/some_resource",
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

      let(:env) do
        build_env(
          response_headers: {
            'Etag' => '_etag_',
            'Cache-Control' => 'public, max-age=27',
            'Vary' => 'Authorization, Accept'
          }
        )
      end

      it 'can be instantiated from a Faraday::Env' do
        entry = Entry.from(env)

        entry.key.must_equal :'some_host.com_/some_resource_'
        entry.etag.must_equal '_etag_'
        entry.must_be :valid?
        entry.must_be :storable?
      end
    end
  end
end
