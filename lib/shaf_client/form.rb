require 'json'
require 'shaf_client/link'

class ShafClient
  class Form < Resource

    def values
      return @values if defined? @values

      @values = attribute(:fields).each_with_object({}) do |d, v|
        v[d['name'].to_sym] = d['value']
      end
    end

    def [](key)
      values[key]
    end

    def []=(key, value)
      values[key] = value
    end

    def target
      attribute(:href)
    end

    def http_method
      attribute(:method).downcase.to_sym
    end

    # def validate; end

    def submit
      client.send(http_method, target, @values)
    end
  end
end
