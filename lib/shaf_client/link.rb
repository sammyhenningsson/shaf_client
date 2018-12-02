class ShafClient
  class Link
    attr_reader :rel, :href, :templated

    def self.from(rel, hash)
      new(rel: rel, href: hash['href'], templated: hash['templated'])
    end

    def initialize(rel:, href:, templated: false)
      @rel = rel.to_sym
      @href = href
      @templated = templated
    end
  end
end
