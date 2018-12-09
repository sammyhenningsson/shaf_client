require 'json'
require 'shaf_client/base_resource'

class ShafClient
  class Resource < BaseResource

    def initialize(client, payload)
      @client = client
      super(payload)
    end

    %i[get put post delete patch get_form].each do |method|
      define_method(method) do |rel, payload = nil|
        href = link(rel).href
        args = [method, href]
        args << payload unless method.to_s.start_with? 'get'
        client.send(*args)
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

    private

    attr_reader :client
  end
end
