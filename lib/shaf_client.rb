require 'faraday'
require 'json'
require 'shaf_client/middleware/cache'
require 'shaf_client/resource'
require 'shaf_client/form'

class ShafClient
  extend Middleware::Cache::Control

  MIME_TYPE_JSON = 'application/json'

  def initialize(root_uri, **options)
    @root_uri = root_uri.dup
    adapter = options.fetch(:faraday_adapter, :net_http)
    setup options

    @client = Faraday.new(url: root_uri) do |conn|
      conn.basic_auth(@user, @pass) if basic_auth?
      conn.use Middleware::Cache, auth_header: auth_header
      conn.adapter adapter
    end
  end

  def get_root(**options)
    get(@root_uri, **options)
  end

  def get_form(uri, **options)
    response = request(method: :get, uri: uri, opts: options)
    Form.new(self, response.body)
  end

  def get_doc(uri, **options)
    response = request(method: :get, uri: uri, opts: options)
    response&.body || ''
  end

  %i[get put post delete patch].each do |method|
    define_method(method) do |uri, payload = nil, **options|
      with_resource do
        request(method: method, uri: uri, payload: payload, opts: options)
      end
    end
  end

  private

  attr_reader :auth_header

  def setup(options)
    setup_default_headers options
    setup_basic_auth options
  end

  def setup_default_headers(options)
    @default_headers = {
      'Content-Type' => options.fetch(:content_type, MIME_TYPE_JSON)
    }
    return unless token = options[:auth_token]

    @auth_header = options.fetch(:auth_header, 'X-Auth-Token')
    @default_headers[@auth_header] = token
  end

  def setup_basic_auth(options)
    @user, @pass = options.slice(:user, :password).values
    @auth_header = options.fetch(:auth_header, 'Authorization') if basic_auth?
  end

  def basic_auth?
    @user && @pass
  end

  def with_resource
    response = yield
    Resource.new(self, response.body)
  end

  def request(method:, uri:, payload: nil, opts: {})
    payload = JSON.generate(payload) if payload&.is_a?(Hash)
    headers = @default_headers.merge(opts.fetch(:headers, {}))
    headers[:skip_cache] = true if opts[:skip_cache]

    @client.send(method) do |req|
      req.url uri
      req.body = payload if payload
      req.headers.merge! headers
    end
  end
end
