require 'json'
require 'shaf_client/link'

class ShafClient
  class Resource
    attr_reader :attributes, :links, :embeds
    def initialize(client, payload)
      @client = client
      @payload = payload
      parse
    end

    def to_s
      attributes
        .merge(_links: links.transform_values(&:to_s))
        .merge(_embedded: embeds.transform_values(&:to_s))
        .to_s
    end

    def attribute(key)
      attributes.fetch(key.to_sym)
    end

    def link(rel)
      links.fetch(rel.to_sym)
    end

    def embedded(rel)
      embeds.fetch(rel.to_sym)
    end

    def [](key)
      attributes[key]
    end

    %i[get put post delete patch get_form].each do |method|
      define_method(method) do |rel, payload = nil|
        href = link(rel).href
        args = [method, href]
        args << payload unless method.to_s.start_with? 'get'
        client.send(*args)
      end
    end

    def actions
      links.keys
    end

    private

    attr_reader :client

    def parse
      return unless @payload
      @attributes = JSON.parse(@payload).transform_keys(&:to_sym)
      @links = parse_links(@attributes.delete(:_links))
      @embeds = parse_embedded(@attributes.delete(:_embedded))
    end

    def parse_links(hash)
      return {} unless hash
      hash.each_with_object({}) do |(key, value), h|
        h[key.to_sym] = Link.from(key, value)
      end
    end

    def parse_embedded(hash)
      # TODO
      {}
    end

    def method_missing(method_name, *args, &block)
      if attributes.key?(method_name)
        attribute[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if attributes.key?(method_name)
      super
    end
  end
end
