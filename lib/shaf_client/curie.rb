# frozen_string_literal: true

require 'shaf_client/link'

class ShafClient
  class Curie < Link
    attr_reader :name

    def self.from(data)
      if data.is_a? Array
        data.map do |d|
          new(name: data['name'], href: d['href'], templated: d['templated'])
        end
      else
        new(name: data['name'], href: data['href'], templated: data['templated'])
      end
    end

    def initialize(name:, href:, templated: nil)
      @name = name
      @href = href
      @templated = !!templated
    end

    def resolve_templated(**args)
      args[:rel] &&= args[:rel].to_s.sub(/#{name}:/, '')
      super(**args)
    end
  end
end
