# frozen_string_literal: true

require 'spec_helper'
require 'shaf_client/middleware/http_cache/env_builder'

class ShafClient
  module Middleware
    class HttpCache
      describe Entry do
        let(:env) do
          EnvBuilder.build(
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
end
