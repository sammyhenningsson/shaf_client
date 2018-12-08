class ShafClient
  class Link
    attr_reader :href, :templated

    def self.from(data)
      if data.is_a? Array
        data.map { |d| new(href: d['href'], templated: d['templated']) }
      else
        new(href: data['href'], templated: data['templated'])
      end
    end

    def initialize(href:, templated: false)
      @href = href
      @templated = templated
    end

    def to_s
      {
        href: href,
        templated: templated
      }.to_s
    end
  end
end
