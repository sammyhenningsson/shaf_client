require 'json'
require 'shaf_client/base_resource'

class ShafClient
  class Resource < BaseResource
    attr_reader :http_status, :headers

    def initialize(client, payload, status = nil, headers = nil)
      @client = client
      @http_status = status
      @headers = headers
      super(payload)
    end

    %i[get put post delete patch get_form].each do |method|
      define_method(method) do |rel, payload = nil, **options|
        href = link(rel).href
        args = [method, href]
        client.send(*args, payload: payload, **options)
      end
    end

    def get_doc(rel:)
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

    def reload!
      self << get(:self, skip_cache: true)
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
