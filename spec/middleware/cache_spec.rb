require 'spec_helper'

class ShafClient
  module Middleware
    module CacheSpec
      class MockResponse
        def initialize(response_env)
          @response_env = response_env
        end

        def on_complete
          yield @response_env
        end
      end

      class MockApp
        def initialize(response_env)
          @response = MockResponse.new(response_env)
        end

        def call(_request_env)
          @response
        end
      end
    end

    describe Cache do
      let(:app_class) do
        Class.new do
        end
      end

      let(:request_env) do
        {
          method: :get,
          url: url,
          body: nil,
          request_headers: {}
        }
      end
      let(:response_env) do
        {
          status: 200,
          url: url,
          body: 'hello',
          response_headers: {
            'cache-control' => 'max-age=30',
            'etag' => 'abc123'
          }
        }
      end
      let(:app) { CacheSpec::MockApp.new(response_env) }
      let(:middleware) { Cache.new(app) }
      let(:url) { '/foo/bar' }
      let(:key) { :"#{url}." }

      after do
        Cache.clear
      end

      it 'saves response in cache' do
        middleware.call(request_env)

        Cache.size.must_equal 1
        payload = Cache.get(key: key)
        payload.must_equal 'hello'
      end

      it 'does not save response unless etag or cache-control in response' do
        response_env[:response_headers] = {}

        middleware.call(request_env)

        Cache.size.must_equal 0
      end

      it 'adds If-None-Match header to request when previous etag is found' do
        Cache.store(
          key: key,
          payload: 'none',
          etag: 'gate'
        )

        middleware.call(request_env)

        request_env.dig(:request_headers, 'If-None-Match').must_equal 'gate'
      end

      it 'does not add If-None-Match header when no previous etag found' do
        Cache.store(
          key: key,
          payload: 'none',
          expire_at: Time.now + 60
        )

        middleware.call(request_env)

        request_env.dig(:request_headers, 'If-None-Match').must_be_nil
      end

      it 'returns stored payload when server responds with 304 Not Modified' do
        Cache.store(
          key: key,
          payload: 'some ol cached payload',
          expire_at: Time.now + 60
        )
        response_env[:status] = 304
        response = middleware.call(request_env)

        response.body.must_equal 'some ol cached payload'
      end
    end
  end
end
