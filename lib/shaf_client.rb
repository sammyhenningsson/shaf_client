require 'faraday'
require 'shaf_client/middleware/cache'
require 'shaf_client/resource'
require 'shaf_client/form'

class ShafClient
  extend Middleware::Cache::Control

  MIME_TYPE_JSON = 'application/json'

  def initialize(root_uri, **options)
    @root_uri = root_uri.dup
    adapter = options.fetch(:faraday_adapter, :net_http)
    setup_default_headers options
    @client = Faraday.new(url: root_uri) do |conn|
      conn.use Middleware::Cache, auth_header: auth_header
      conn.adapter adapter
    end
  end

  def get_root
    get(@root_uri)
  end

  def get_form(uri)
    response = request(method: :get, uri: uri)
    Form.new(self, response.body)
  end

  %i[get put post delete patch].each do |method|
    define_method(method) do |uri, payload = nil|
      with_resource do
        request(method: method, uri: uri, payload: payload)
      end
    end
  end

  private

  attr_reader :auth_header

  def setup_default_headers(options)
    @default_headers = {
      'Content-Type' => options.fetch(:content_type, MIME_TYPE_JSON)
    }
    return unless token = options[:auth_token]

    @auth_header = options.fetch(:auth_header, 'X-Auth-Token')
    @default_headers[@auth_header] = token
  end

  def with_resource
    response = yield
    Resource.new(self, response.body)
  end

  def request(method:, uri:, payload: nil, headers: {})
    payload = JSON.generate(payload) if payload&.is_a?(Hash)
    @client.send(method) do |req|
      req.url uri
      req.body = payload if payload
      req.headers.merge! @default_headers.merge(headers)
    end
  end
end
