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
      attributes.dup.tap do |hash|
        hash[:_links] = transform_values_to_s(links)
        embedded = transform_values_to_s(embedded_resources)
        hash[:_embedded] = embedded unless embedded.empty?
      end
    end

    def to_s
      JSON.pretty_generate(to_h)
    end

    def attribute(key)
      raise Error, "No attribute for key: #{key}" unless attributes.key? key
      attributes.fetch(key.to_sym)
    end

    def link(rel)
      rewritten_rel = best_match(links.keys, rel)
      raise Error, "No link with rel: #{rel}" unless links.key? rewritten_rel
      links[rewritten_rel]
    end

    def curie(rel)
      raise Error, "No curie with rel: #{rel}" unless curies.key? rel.to_sym
      curies[rel.to_sym]
    end

    def embedded(rel)
      rewritten_rel = best_match(embedded_resources.keys, rel)
      unless embedded_resources.key? rewritten_rel
        raise Error, "No embedded resources with rel: #{rel}"
      end
      embedded_resources[rewritten_rel]
    end

    def rel?(rel)
      !link(rel).nil?
    rescue StandardError
      false
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
      @links ||= {}
      @curies ||= {}

      (attributes.delete(:_links) || {}).each do |key, value|
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
      return super unless attributes.key?(method_name)
      attribute(method_name)
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if attributes.key?(method_name)
      super
    end

    def best_match(rels, rel)
      rel = rel.to_sym
      return rel if rels.include? rel

      unless rel.to_s.include? ':'
        matches = rels.grep(/[^:]*:#{rel}/)
        return matches.first if matches.size == 1
        raise AmbiguousRelError, "Ambiguous rel: #{rel}. (#{matches})" if matches.size > 1
      end

      best_match(rels, rel.to_s.tr('_', '-')) if rel.to_s.include? '_'
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
