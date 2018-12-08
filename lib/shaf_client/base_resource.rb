require 'json'
require 'shaf_client/link'

class ShafClient
  class BaseResource
    attr_reader :attributes, :links, :embeds

    def initialize(payload)
      @payload =
        if payload&.is_a? String
          JSON.parse(payload)
        else
          payload
        end
      parse if @payload
    end

    def to_s
      attributes
        .merge(_links: transform_values_to_s(links))
        .merge(_embedded: transform_values_to_s(embeds))
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

    def actions
      links.keys
    end

    private

    def parse
      @attributes = @payload.transform_keys(&:to_sym)
      @links = parse_links(@attributes.delete(:_links))
      @embeds = parse_embedded(@attributes.delete(:_embedded))
    end

    def parse_links(hash)
      return {} unless hash
      hash.each_with_object({}) do |(key, value), h|
        h[key.to_sym] = Link.from(value)
      end
    end

    def parse_embedded(hash)
      return {} unless hash
      hash.each_with_object({}) do |(key, value), h|
        h[key.to_sym] =
          if value.is_a? Array
            value.map { |d| BaseResource.new(d) }
          else
            BaseResource.new(value)
          end
      end
    end

    def method_missing(method_name, *args, &block)
      if attributes.key?(method_name)
        attribute(method_name)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if attributes.key?(method_name)
      super
    end

    def transform_values_to_s(hash)
      hash.transform_values do |value|
        if value.is_a? Array
          value.map(&:to_s)
        else
          value.to_s
        end
      end
    end
  end
end
