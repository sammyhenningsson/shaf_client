# frozen_string_literal: true

require 'spec_helper'

describe ShafClient do
  let(:root_url) { 'http://api.root.com' }
  let(:client) { ShafClient.new(root_url, faraday_adapter: :test) }
  let(:stubs) { client.stubs }

  def stub_response(method: :get, uri:, payload: "", status: 200, headers: {})
    headers['Content-Type'] ||= 'application/hal+json'
    stubs.send(method, uri) do |_env|
      [status, headers, payload]
    end
  end

  it 'returns a Resource' do
    stub_response(uri: '/stuff', payload: <<~JSON)
      {
        "message": "hello",
        "_links": {
          "self": {"href": "/stuff"}
        }
      }
    JSON

    response = client.get('/stuff')

    response.must_be_instance_of ShafClient::Resource
    response.message.must_equal 'hello'
  end

  it 'returns a Form' do
    response_headers = {'Content-Type' => 'application/hal+json;profile=shaf-form'}

    stub_response(uri: '/form', headers: response_headers, payload: <<~JSON)
      {
        "method": "POST",
        "name": "create-stuff",
        "title": "Create new stuff",
        "href": "/stuff",
        "type": "application/json",
        "_links": {
          "self": {"href": "/form"}
        },
        "fields": [
          {
            "name": "title",
            "type": "string"
          }
        ]
      }
    JSON

    response = client.get('/form')

    response.must_be_instance_of ShafClient::Form
    response.http_method.must_equal :post
  end

  it 'returns an EmptyResource' do
    stub_response(uri: '/empty', status: 204, headers: {foo: 'bar'})
    response = client.get('/empty')

    response.must_be_instance_of ShafClient::EmptyResource
    response.headers[:foo].must_equal 'bar'
    response.http_status.must_equal 204
  end

  it 'returns an UnknownResource' do
    stub_response(
      uri: '/unknown',
      headers: {'Content-Type' => 'text/plain'},
      payload: "hello"
    )
    response = client.get('/unknown')

    response.must_be_instance_of ShafClient::UnknownResource
    response.headers[:content_type].must_equal 'text/plain'
    response.http_status.must_equal 200
    response.body.must_equal 'hello'
  end
end
