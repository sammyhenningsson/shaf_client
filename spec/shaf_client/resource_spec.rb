require 'spec_helper'

describe ShafClient::Resource do
  let(:root_url) { 'http://api.root.com' }
  let(:client) { ShafClient.new(root_url, faraday_adapter: :test) }
  let(:stubs) { client.stubs }
  let(:resource) do
    ShafClient::Resource.new(
      client,
      document,
      200,
      {'content-type' => ShafClient::MIME_TYPE_HAL}
    )
  end
  let(:document) do
    <<~JSON
      {
        "title": "hello",
        "message": "world",
        "user_id": 1,
        "_links": {
          "doc:up": {
            "href": "http://localhost:3000/posts",
            "title": "up"
          },
          "self": {
            "href": "http://localhost:3000/posts/1"
          },
          "doc:edit-form": {
            "href": "http://localhost:3000/posts/1/edit",
            "title": "edit"
          },
          "doc:delete": {
            "href": "http://localhost:3000/posts/1",
            "title": "delete"
          },
          "doc:author": {
            "href": "http://localhost:3000/users/1"
          },
          "curies": [
            {
              "name": "doc",
              "href": "http://localhost:3000/doc/post/rels/{rel}",
              "templated": true
            }
          ]
        },
        "_embedded": {
          "doc:author": {
            "name": "Jane Doe",
            "_links": {
              "self": {
                "href": "http://localhost:3000/users/1"
              }
            }
          },
          "doc:commments": [
            {
              "text": "good stuff",
              "_links": {
                "self": {
                  "href": "http://localhost:3000/comments/1"
                }
              }
            }
          ]
        }
      }
    JSON
  end

  def stub_response(method: :get, uri:, payload: "", status: 200, headers: {})
    headers['Content-Type'] ||= ShafClient::MIME_TYPE_HAL
    stubs.send(method, uri) do
      [status, headers, payload]
    end
  end

  it 'can fetch a link by rel' do
    payload = JSON.generate(
      attr: 'posts',
      _links: {
        self: {href: '/posts'}
      }
    )
    stub_response(
      uri: 'http://localhost:3000/posts',
      payload: payload,
      status: 250,
      headers: {foo: 'bar'}
    )

    response = resource.get(:up)

    _(response.attribute(:attr)).must_equal 'posts'
    _(response.http_status).must_equal 250
  end

  it 'returns an embedded resource instead of fetching from link' do
    response = resource.get(:author)

    _(response.attribute(:name)).must_equal 'Jane Doe'
    _(response.http_status).must_equal 203
  end

  it 'can get documentation from curie' do
    stub_response(
      method: :get,
      uri: 'http://localhost:3000/doc/post/rels/up',
      status: 200,
      payload: 'some description..',
      headers: {'Content-Type' => 'text/plain'}
    )

    response = resource.get_doc('doc:up')

    _(response.http_status).must_equal 200
    _(response.body).must_equal 'some description..'
  end

  it 'can delete itself' do
    stub_response(
      method: :delete,
      uri: 'http://localhost:3000/posts/1',
      status: 204
    )

    response = resource.destroy!

    _(response.http_status).must_equal 204
  end
end
