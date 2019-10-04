require 'json'
require 'shaf_client/resource_mapper'
require 'shaf_client/base_resource'

class ShafClient
  class Resource < BaseResource
    attr_reader :http_status, :headers

    ResourceMapper.register("application/hal+json", self)

    def self.content_type(type)
      ResourceMapper.register(type, self)
    end

    def self.profile(name)
      content_type "application/hal+json;profile=#{name}"
    end

    def self.build(client, payload, status = nil, headers = {})
      content_type = headers.fetch('content-type', '')
      ResourceMapper.for(content_type).new(client, payload, status, headers)
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

    %i[get put post delete patch].each do |method|
      define_method(method) do |rel, payload = nil, **options|
        href = link(rel).href
        client.send(method, href, payload: payload, **options)
      end
    end

    def get_doc(rel)
      rel = rel.to_s
      curie_name, rel =
        if rel.include? ':'
          rel.split(':')
        else
          [:doc, rel]
        end

      curie = curie(curie_name)
      uri = curie.resolve_templated(rel: rel)
      client.get_doc(uri)
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

    protected

    def <<(other)
      @http_status  = other.http_status.dup
      @headers      = other.headers.dup
      super
    end

    private

    attr_reader :client
  end
end
