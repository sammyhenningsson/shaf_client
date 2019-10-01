# frozen_string_literal: true

require 'faraday'
require 'faraday-http-cache'

# FIXME remove this when faraday-http-cache has released  this fix
# https://github.com/plataformatec/faraday-http-cache/pull/116
require 'faraday_http_cache_patch'

require 'json'
require 'shaf_client/error'
require 'shaf_client/middleware/redirect'
require 'shaf_client/resource'
require 'shaf_client/shaf_form'
require 'shaf_client/hal_form'
require 'shaf_client/api_error'
require 'shaf_client/empty_resource'
require 'shaf_client/unknown_resource'

class ShafClient
  MIME_TYPE_JSON = 'application/json'
  MIME_TYPE_HAL  = 'application/hal+json'
  DEFAULT_ADAPTER = :net_http

  def initialize(root_uri, **options)
    @root_uri = root_uri.dup
    @options = options

    setup_default_headers
    setup_basic_auth
    setup_client
  end

  def get_root(**options)
    get(@root_uri, **options)
  end

  %i[get put post delete patch].each do |method|
    define_method(method) do |uri, payload: nil, **options|
      response = request(
        method: method,
        uri: uri,
        payload: payload,
        opts: options
      )

      body = String(response.body)
      response.headers['content-type'] = nil if body.empty?

      Resource.build(self, body, response.status, response.headers)
    end
  end

  def stubs
    return unless @adapter == :test
    @stubs ||= Faraday::Adapter::Test::Stubs.new
  end

  private

  attr_reader :options, :auth_header

  def setup_default_headers
    @default_headers = {
      'Content-Type' => options.fetch(:content_type, MIME_TYPE_JSON),
      'Accept' => options.fetch(:accept, MIME_TYPE_HAL)
    }
    return unless token = options[:auth_token]

    @auth_header = options.fetch(:auth_header, 'X-Auth-Token')
    @default_headers[@auth_header] = token
  end

  def setup_basic_auth
    @user, @pass = options.slice(:user, :password).values
    @auth_header = options.fetch(:auth_header, 'Authorization') if basic_auth?
  end

  def basic_auth?
    @user && @pass
  end

  def setup_client
    @adapter = options.fetch(:faraday_adapter, DEFAULT_ADAPTER)
    cache_params = faraday_cache_params(options)

    @client = Faraday.new(url: @root_uri) do |conn|
      conn.basic_auth(@user, @pass) if basic_auth?
      conn.use Middleware::Redirect
      conn.use Faraday::HttpCache, **cache_params
      connect_adapter(conn)
    end
  end

  def faraday_cache_params(options)
    options.fetch(:faraday_http_cache, {}).tap do |cache_params|
      cache_params[:store] ||= options[:http_cache_store] if options[:http_cache_store]
      cache_params[:shared_cache] ||= false
      cache_params[:serializer] ||= Marshal
    end
  end

  def connect_adapter(connection)
    args = [@adapter]
    args << stubs if @adapter == :test
    connection.adapter(*args)
  end

  def request(method:, uri:, payload: nil, opts: {})
    payload = JSON.generate(payload) if payload&.is_a?(Hash)
    headers = default_headers(method).merge(opts.fetch(:headers, {}))

    @client.send(method) do |req|
      req.url uri
      req.body = payload if payload
      req.headers.merge! headers
    end
  rescue StandardError => e
    raise Error, e.message
  end

  def default_headers(http_method)
    headers = @default_headers.dup
    headers.delete('Content-Type') unless %i[put patch post].include? http_method
    headers
  end
end
