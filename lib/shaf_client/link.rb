# frozen_string_literal: true

class ShafClient
  class Link
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

    def templated?
      @templated
    end

    def href
      @href.dup
    end

    def resolve_templated(**args)
      return href unless templated?

      href
        .yield_self { |href| resolve_required(href, **args) }
        .yield_self { |href| resolve_optional(href, **args) }
    end

    def to_h
      {
        href: href,
        templated: templated?
      }
    end

    private

    def resolve_required(href, **args)
      String(href).gsub(/{(?!\?)([^}]*)}/) do
        key = $1.to_sym
        args.fetch key do
          raise ArgumentError, "missing keyword: :#{key}"
        end
      end
    end

    def resolve_optional(href, **args)
      String(href).gsub(/{\?([^}]*)}/) do
        values = []
        $1.split(',').each do |key|
          next unless args.key? key.to_sym
          values << "#{key}=#{args[key.to_sym]}"
        end

        next '' if values.empty?
        "?#{values.join('&')}"
      end
    end
  end
end
