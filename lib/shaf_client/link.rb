# frozen_string_literal: true

class ShafClient
  class Link
    attr_reader :templated

    def self.from(data)
      if data.is_a? Array
        data.map { |d| new(href: d['href'], templated: d['templated']) }
      else
        new(href: data['href'], templated: data['templated'])
      end
    end

    def initialize(href:, templated: false)
      @href = href
      @templated = !!templated
    end

    alias templated? templated

    def href
      @href.dup
    end

    def resolve_templated(**args)
      return href unless templated?

      args.inject(href) do |uri, (key, value)|
        value = value.to_s.sub(/.+:/, '')
        uri.sub(/{#{key}}/, value)
      end
    end

    def to_h
      {
        href: href,
        templated: templated?
      }
    end
  end
end
