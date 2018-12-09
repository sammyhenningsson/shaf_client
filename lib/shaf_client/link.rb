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

    def initialize(href:, templated: nil)
      @href = href
      @templated = !!templated
    end

    alias templated? templated

    def href
      @href.dup
    end

    def resolve_templated(**args)
      return unless templated?

      args.inject(href) do |uri, (key, value)|
        value = value.to_s.sub(/.+:/, '')
        uri.sub(/{#{key}}/, value)
      end
    end

    def to_s
      {
        href: href,
        templated: templated?
      }.to_s
    end
  end
end
