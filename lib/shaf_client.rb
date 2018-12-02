require 'faraday'
require 'shaf_client/middleware/cache'
require 'shaf_client/resource'

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

  def get(uri, **headers)
    with_resource do
      request(method: :get, uri: uri, headers: headers)
    end
  end

  def with_resource
    response = yield
    body = response.respond_to?(:body) ? response.body : response
    Resource.new(self, body)
  end

  def request(method:, uri:, payload: nil, headers:)
    @client.send(method) do |req|
      req.url uri
      req.body = payload if payload
      req.headers.merge! @default_headers.merge(headers)
    end
  end
end
