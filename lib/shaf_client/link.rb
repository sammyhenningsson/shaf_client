class ShafClient
  class Link
    attr_reader :rel, :href, :templated

    def self.from(rel, data)
      if data.is_a? Array
        data.map { |d| new(rel: rel, href: d['href'], templated: d['templated']) }
      else
        new(rel: rel, href: data['href'], templated: data['templated'])
      end
    end

    def initialize(rel:, href:, templated: false)
      @rel = rel.to_sym
      @href = href
      @templated = templated
    end

    def to_s
      {
        rel: rel,
        href: href,
        templated: templated
      }.to_s
    end
  end
end
