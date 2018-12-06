require 'faraday'
require 'shaf_client/middleware/cache'
require 'shaf_client/resource'
require 'shaf_client/form'

class ShafClient
  extend Middleware::Cache::Control

  MIME_TYPE_JSON = 'application/json'

  def initialize(root_uri, **headers)
    @root_uri = root_uri.dup
    @default_headers = headers.merge('Content-Type' => MIME_TYPE_JSON)
    @client = Faraday.new(url: root_uri) do |conn|
      conn.use Middleware::Cache
      # Last middleware must be the adapter:
      conn.adapter :net_http # switch to persistent??
    end
  end

  def get_root
    get(@root_uri)
  end

  %i[get put post delete patch].each do |method|
    define_method(method) do |uri, payload = nil|
      with_resource do
        request(method: method, uri: uri, payload: payload)
      end
    end
  end

  def get_form(uri)
    response = request(method: :get, uri: uri)
    Form.new(self, response.body)
  end

  def with_resource
    response = yield
    Resource.new(self, response.body)
  end

  def request(method:, uri:, payload: nil, headers: {})
    payload = JSON.generate(payload) if payload && !payload.is_a?(String)
    @client.send(method) do |req|
      req.url uri
      req.body = payload if payload
      req.headers.merge! @default_headers.merge(headers)
    end
  end
end
