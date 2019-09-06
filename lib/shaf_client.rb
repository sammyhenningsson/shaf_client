# frozen_string_literal: true

require 'faraday'
require 'faraday-http-cache'
require 'json'
require 'shaf_client/middleware/redirect'
require 'shaf_client/resource'
require 'shaf_client/form'

class ShafClient
  class Error < StandardError; end

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

  def get_doc(uri, **options)
    response = request(method: :get, uri: uri, opts: options)
    response&.body || ''
  end

  %i[get put post delete patch].each do |method|
    define_method(method) do |uri, payload: nil, **options|
      response = request(
        method: method,
        uri: uri,
        payload: payload,
        opts: options
      )
      status = response.status
      response.headers['content-type'] = 'profile=__shaf_client_emtpy__' unless response.body
      Resource.build(self, response.body, status, response.headers)
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
    options.fetch(:faraday_http_cache, shared_cache: false).tap do |cache_params|
      cache_params[:store] ||= options[:http_cache_store] if options[:http_cache_store]
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
