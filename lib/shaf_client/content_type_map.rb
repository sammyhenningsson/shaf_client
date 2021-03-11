require 'forwardable'

class ShafClient
  class ContentTypeMap
    extend Forwardable

    def_delegators :@map, :default, :default=, :keys, :values, :each

    def initialize
      @map = {}
    end

    def [](content_type, profile = nil)
      key = key_for(content_type, profile)
      map.fetch(key) do
        key = key_for(content_type, nil)
        map[key]
      end
    end

    def []=(content_type, profile = nil, value)
      key = key_for(content_type, profile)
      map[key] = value
    end

    def key?(content_type, profile = nil)
      key = key_for(content_type, profile)
      map.key? key
    end

    def delete(content_type, profile = nil)
      key = key_for(content_type, profile)
      map.delete(key)
    end

    def key_for(content_type, profile)
      return unless content_type

      key = content_type.to_s.downcase
      key = strip_parameters(key)
      key << "_#{profile.to_s.downcase}" if profile
      key
    end

    private

    attr_reader :map

    def strip_parameters(content_type)
      content_type&.sub(/;.*/, '')
    end
  end
end
