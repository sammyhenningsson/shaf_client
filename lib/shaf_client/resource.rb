require 'json'

module ShafClient
  class Resource
    attr_reader :attributes, :links, :embeds
    def initialize(client, payload)
      @client = client
      @payload = payload
      parse
    end

    private

    attr_reader :client

    def parse
      return unless @payload
      @attributes = JSON.parse(@payload).transform_keys(&:to_sym)
      @links = parse_links(@attributes.delete(:_links))
      @embeds = @attributes.delete(:_embedded)
    end

    def parse_links(hash)
      return {} unless hash
      hash.each_with_object({}) do |(key, value), h|
        h[key.to_sym] = Link.from(key, value)
      end
    end

    # def parse_embedded(hash)
    #   # TODO
    # end

    def attribute(key)
      attributes[key.to_sym]
    end

    def link(rel)
      links[rel.to_sym]
    end

    def embedded(rel)
      embeds[rel.to_sym]
    end

    def follow_link(rel)
      client.get(link(rel).href)
    end

    def method_missing(method_name, *args, &block)
      if attributes.key?(method_name)
        attribute[method_name]
      elsif links.key?(method_name)
        follow_link(method_name)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if attributes.key?(method_name)
      return true if links.key?(method_name)
      return true if embeds.key?(method_name)
      super
    end
  end
end
