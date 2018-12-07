require 'spec_helper'

describe ShafClient do
  let(:root_url) { 'http://foo.com' }
  let(:client) { ShafClient.new(root_url) }

  def set_payload(uri, payload, auth_token: "")
    unless uri.start_with? root_url
      uri.prepend('/') unless uri.start_with? '/'
      uri.prepend root_url
    end

    payload = JSON.generate(payload) if payload&.is_a? Hash
    key       = :"#{uri}.#{auth_token}"
    expire_at = Time.now + 60

    ShafClient::Middleware::Cache.store(
      key: key,
      payload: payload,
      expire_at: expire_at
    )
  end

  before do
    set_payload(
      '/stuff',
      message: 'hello',
      _links: {
        self: {href: '/stuff'}
      }
    )

    set_payload(
      '/stuff',
      {
        message: 'hello authenticated user',
        _links: {
          self: {href: '/stuff'}
        }
      },
      auth_token: 'foobar'
    )

    set_payload(
      '/form',
      method: 'POST',
      name: 'create-stuff',
      title: 'Create new stuff',
      href: '/stuff',
      type: 'application/json',
      _links: {
        self: {href: '/form'}
      },
      fields: [
        {
          'name': 'title',
          'type': 'string'
        }
      ]
    )
  end

  after do
    ShafClient::Middleware::Cache.clear
  end

  it 'returns a Resource' do
    response = client.get('/stuff')

    response.must_be_instance_of ShafClient::Resource
    response[:message].must_equal 'hello'
  end

  it '#get_form returns a Form' do
    response = client.get_form('/form')

    response.must_be_instance_of ShafClient::Form
    response.http_method.must_equal :post
  end

  it 'returns another respresentation of Resource when authenticated' do
    client = ShafClient.new(root_url, auth_token: 'foobar')
    response = client.get('/stuff')

    response.must_be_instance_of ShafClient::Resource
    response[:message].must_equal 'hello authenticated user'
  end
end
