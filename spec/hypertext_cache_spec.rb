# frozen_string_literal: true

require 'json'
require 'shaf_client'
require 'spec_helper'

describe "Hypertext Cache Pattern" do
  # See https://tools.ietf.org/html/draft-kelly-json-hal-08#section-8.3
  let(:client) { ShafClient.new('http://api.root.com', faraday_adapter: :test) }
  let(:stubs) { client.stubs }
  let(:author_path) { '/people/alan-watts' }
  let(:post) do
    JSON.generate(
      {
        _links: {
          self: {
            href: '/blog-post'
          },
          author: {
            href: author_path
          }
        },
        _embedded: {
          author: {
            _links: {
              self: {
                'href': author_path
              }
            },
            name: 'Alan Watts',
            born: 'January 6, 1915',
            died: 'November 16, 1973'
          }
        }
      }
    )
  end
  let(:author) do
    JSON.generate(
      {
        _links: {
          self: {
            href: author_path
          },
        },
        name: 'Nalan Sttaw',
        born: 'January 6, 1915',
        died: 'November 16, 1973'
      }
    )
  end
  let(:resource) { ShafClient::Resource.new(client, post) }
  let(:mock_resource) { Class.new(ShafClient::Resource) }
  let(:content_type) { "#{ShafClient::MIME_TYPE_HAL};foobar" }

  before do
    ShafClient::ResourceMapper.register(content_type, mock_resource)
  end

  after do
    ShafClient::ResourceMapper.unregister(content_type)
  end

  it 'returns the embedded resource' do
    stubs.get(author_path) do
      raise 'An HTTP request was made. But expected behavior is to return the embedded resource'
    end

    response = resource.get(:author)

    _(response).must_be_instance_of ShafClient::Resource
    _(response.name).must_equal 'Alan Watts'
    _(response.http_status).must_equal 203
  end

  it 'fetches the resource from the link' do
    stubs.get(author_path) do
      [200, {'Content-Type' => ShafClient::MIME_TYPE_HAL}, author]
    end

    response = resource.get(:author, hypertext_cache_strategy: :no_cache)
    _(response).must_be_instance_of ShafClient::Resource
    _(response.name).must_equal 'Nalan Sttaw'
    _(response.http_status).must_equal 200
  end

  it 'performs a HEAD request to get the right headers' do
    stubs.head(author_path) do
      [299, {'content-type' => content_type}, ""]
    end

    response = resource.get(:author, hypertext_cache_strategy: :fetch_headers)

    _(response).must_be_instance_of mock_resource
    _(response.name).must_equal 'Alan Watts'
    _(response.http_status).must_equal 299
  end
end
