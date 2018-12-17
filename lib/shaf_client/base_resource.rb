require 'json'
require 'shaf_client/link'
require 'shaf_client/curie'

class ShafClient
  class BaseResource
    attr_reader :attributes, :links, :curies, :embedded_resources

    def initialize(payload)
      @payload =
        if payload&.is_a? String
          JSON.parse(payload)
        else
          payload
        end

      parse
    end

    def to_h
      attributes
        .merge(_links: transform_values_to_s(links))
        .merge(_embedded: transform_values_to_s(embedded_resources))
    end

    def to_s
      JSON.pretty_generate(to_h)
    end

    def attribute(key)
      attributes.fetch(key.to_sym)
    end

    def link(rel)
      links.fetch(rel.to_sym)
    end

    def curie(rel)
      curies.fetch(rel.to_sym)
    end

    def embedded(rel)
      embedded_resources.fetch(rel.to_sym)
    end

    def [](key)
      attributes[key]
    end

    def actions
      links.keys
    end

    protected

    def payload
      @payload ||= {}
    end

    def <<(other)
      @payload            = other.payload.dup
      @attributes         = other.attributes.dup
      @links              = other.links.dup
      @curies             = other.curies.dup
      @embedded_resources = other.embedded_resources.dup
      self
    end

    private

    def parse
      @attributes = payload.transform_keys(&:to_sym)
      parse_links
      parse_embedded
    end

    def parse_links
      links = attributes.delete(:_links) || {}
      @links ||= {}
      @curies ||= {}

      links.each do |key, value|
        next parse_curies(value) if key == 'curies'
        @links[key.to_sym] = Link.from(value)
      end
    end

    def parse_curies(curies)
      curies.each do |value|
        curie = Curie.from(value)
        @curies[curie.name.to_sym] = curie
      end
    end

    def parse_embedded
      embedded = @attributes.delete(:_embedded) || {}
      @embedded_resources ||= {}

      embedded.each do |key, value|
        @embedded_resources[key.to_sym] =
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
          value.map(&:to_h)
        else
          value.to_h
        end
      end
    end
  end
end
