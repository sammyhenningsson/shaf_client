require 'shaf_client/alps/descriptor'

class ShafClient
  class AlpsJson < Resource
    content_type MIME_TYPE_ALPS_JSON

    attr_reader :descriptors

    def initialize(_client, payload, status = nil, headers = {})
      super

      @links = {}.freeze
      @curies = {}.freeze
      @embedded_resources = {}.freeze
    end

    def to_h
      attributes.merge(
        descriptors: descriptors.map(&:to_h)
      )
    end

    def descriptor(id)
      descriptors.find { |desc| desc.id == id.to_sym }
    end

    def each_descriptor(&block)
      descriptors.each(&block)
    end

    private

    def parse
      alps = payload&.dig('alps') || {}
      @attributes = {
        version: alps['version'],
        doc: alps['doc'],
      }
      @descriptors = alps.fetch('descriptor', []).map do |desc|
        Alps::Descriptor.new(**desc.transform_keys(&:to_sym))
      end
    end
  end
end
