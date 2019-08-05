require 'spec_helper'
require 'shaf_client/middleware/http_cache/env_builder'

class ShafClient
  module Middleware
    describe HttpCache do
      let(:url) { '/foo/bar' }
      let(:response_headers) do
        {
          'cache-control' => 'max-age=30',
          'etag' => 'abc123'
        }
      end
      let(:stubs) { Faraday::Adapter::Test::Stubs.new }
      let(:accessor) { Object.new }
      let(:client) do
        Faraday.new do |conn|
          conn.use HttpCache, cache_class: HttpCache::InMemory, accessed_by: accessor
          conn.adapter(:test, stubs)
        end
      end

      after do
        stubs.verify_stubbed_calls
      end

      describe 'the cache can be controlled through an object passed to the :accessed_by kw arg' do
        it 'possible to access the cache' do
          stubs.get(url) { [200, response_headers, 'hello'] }
          client.get url
          accessor.cache_size.must_equal 1

          accessor.clear_cache

          accessor.cache_size.must_equal 0
        end
      end

      it 'saves response in cache' do
        stubs.get(url) { [200, response_headers, 'hello'] }
        client.get url
        accessor.cache_size.must_equal 1
      end

      it 'does not save response unless etag or cache-control in response' do
        stubs.get(url) { [200, {}, 'hello'] }

        client.get url

        accessor.cache_size.must_equal 0
      end

      it 'saves response when Vary specifies header that we requested' do
        stubs.get(url) { [200, response_headers.merge('vary' => 'Foobar'), 'hello'] }
        client.get(url, nil, 'Foobar' => 'baz')
        accessor.cache_size.must_equal 1
      end

      it 'does not save response when Vary specifies header that we did not send' do
        stubs.get(url) { [200, response_headers.merge('vary' => 'Foobar'), 'hello'] }
        client.get url
        accessor.cache_size.must_equal 0
      end

      it 'adds If-None-Match header to request when previous etag is found' do
        checksum = nil
        stubs.get(url) do |env|
          checksum = env.request_headers['If-None-Match']
          [200, {'etag' => 'gate'}, 'hello']
        end

        client.get url
        checksum.must_be_nil

        client.get url
        checksum.must_equal 'gate'
      end

      it 'returns stored payload when server responds with 304 Not Modified' do
        stubs.get(url) { [200, {'etag' => 'gate'}, 'static'] }
        client.get url

        stubs.get(url) { [304, response_headers, ''] }
        response = client.get url

        response.status.must_equal 304
        response.body.must_equal 'static'
      end
    end
  end
end
