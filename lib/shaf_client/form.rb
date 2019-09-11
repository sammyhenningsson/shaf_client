require 'json'
require 'shaf_client/link'
require 'shaf_client/field'

class ShafClient
  class Form < Resource

    def values
      return @values if defined? @values

      @values = fields.each_with_object({}) do |field, values|
        values[field.name] = field.value
      end
    end

    def [](key)
      values.fetch(key.to_sym)
    end

    def []=(key, value)
      values.fetch(key.to_sym) # Raise KeyError unless key exist!
      values[key.to_sym] = value
    end

    def title
      raise NotImplementedError
    end

    def target
      raise NotImplementedError
    end

    def http_method
      raise NotImplementedError
    end

    def content_type
      raise NotImplementedError
    end

    def fields
      raise NotImplementedError
    end

    def submit
      client.send(
        http_method,
        target,
        payload: encoded_payload,
        headers: {'Content-Type' => content_type}
      )
    end

    def valid?
      field_value_mapping

      fields.all? do |field|
        value = values[field.name.to_sym]
        field.valid? value
      end
    end

    protected

    def <<(other)
      @values = {}
      other.values.each do |key, value|
        @values[key] = value.dup
      end
      super
    end

    private

    def encoded_payload
      if content_type&.downcase == 'application/x-www-form-urlencoded'
        raise NotImplementedError
        # urlencode(values)
      else
        JSON.generate(values) 
      end
    end

    def field_names
      fields.map { |f| f.name.to_sym }
    end

    def field_value_mapping
      field_names.each_with_object({}) do |name, mapping|
        mapping[name.to_sym] = values[name.to_sym]
      end
    end
  end
end
