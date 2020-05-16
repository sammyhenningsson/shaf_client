require 'json'
require 'shaf_client/resource_mapper'
require 'shaf_client/base_resource'

class ShafClient
  class Resource < BaseResource
    include MimeTypes

    attr_reader :http_status, :headers

    ResourceMapper.register(MIME_TYPE_HAL, self)

    def self.content_type(type)
      ResourceMapper.register(type, self)
    end

    def self.profile(name)
      content_type "#{MIME_TYPE_HAL};profile=#{name}"
    end

    def self.build(client, payload, content_type = MIME_TYPE_HAL, status = nil, headers = {})
      ResourceMapper.for(content_type)
        .new(client, payload, status, headers)
    end

    def initialize(client, payload, status = nil, headers = {})
      @client = client
      @http_status = status
      @headers = headers
      super(payload)
    end

    def inspect
      <<~RESOURCE
        Status: #{http_status}
        Headers: #{headers}
        #{to_s}
      RESOURCE
    end

    %i[put post delete patch].each do |method|
      define_method(method) do |rel, payload = nil, **options|
        href = link(rel).href
        client.send(method, href, payload: payload, **options)
      end
    end

    def get(rel, **options)
      href = link(rel).href
      embedded_resource = _embedded(rel)
      cached_resource = hypertext_cache_resource(href, embedded_resource, options)
      cached_resource || client.get(href, **options)
    end

    def get_doc(rel, **options)
      rel = rel.to_s
      curie_name, rel =
        if rel.include? ':'
          rel.split(':')
        else
          [:doc, rel]
        end

      curie = curie(curie_name)
      uri = curie.resolve_templated(rel: rel)
      client.get(uri, options)
    end

    def get_hal_form(rel)
      href = link(rel).href
      uri = rel.to_s
      if uri.match? %r{:[^/]}
        curie_name, rel = rel.split(':')
        curie = curie(curie_name)
        uri = curie.resolve_templated(rel: rel)
      end

      headers = {'Accept': 'application/prs.hal-forms+json'}
      client.get(uri, headers: headers).tap do |form|
        form.target = href if form.respond_to? :target= 
      end
    end

    def reload!
      self << get(:self, headers: {'Cache-Control': 'no-cache'})
    end

    def destroy!
      delete(:delete)
    end

    def content_type
      headers['content-type']
    end

    protected

    def <<(other)
      @http_status  = other.http_status.dup
      @headers      = other.headers.dup
      super
    end

    private

    attr_reader :client

    def hypertext_cache_strategy(options)
      options.fetch(:hypertext_cache_strategy) do
        ShafClient.default_hypertext_cache_strategy
      end
    end

    def hypertext_cache?(options)
      HypertextCacheStrategy.cacheable? hypertext_cache_strategy(options)
    end

    def hypertext_cache_resource(href, embedded_resource, options)
      return unless embedded_resource

      cache_strategy = hypertext_cache_strategy(options)
      return unless HypertextCacheStrategy.cacheable? cache_strategy

      if HypertextCacheStrategy.fetch_headers? cache_strategy
        resource = client.head(href, options)
        status = resource.http_status
        headers = resource.headers
        embedded_resource = embedded_resource.payload
      else
        status = HypertextCacheStrategy.default_http_status
        headers = HypertextCacheStrategy.default_headers
      end

      self.class.build(client, embedded_resource, headers['content-type'], status, headers)
    end
  end
end
