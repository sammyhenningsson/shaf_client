require 'json'
require 'shaf_client/link'

class ShafClient
  class Form < Resource

    profile 'shaf-form'

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

    def submit
      client.send(http_method, target, payload: @values)
    end

    def reload!
      self << get(:self, skip_cache: true)
    end

    def valid?
      attribute(:fields).all? do |field|
        valid_field? field
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

    def valid_field?(field)
      key = field['name'].to_sym
      return false unless validate_required(field, key)
      return false unless validate_number(field, key)
      return false unless validate_string(field, key)
      true
    end

    private

    def validate_required(field, key)
      return true unless field['required']
      return false if values[key].nil?
      return false if values[key].respond_to?(:empty) && values[key].empty?
      true
    end

    def validate_string(field, key)
      return true unless %w[string text].include? field.fetch('type', '').downcase
      return false if values[key]&.is_a?(Numeric)
      true
    end

    def validate_number(field, key)
      return true unless %w[int integer number].include? field.fetch('type', '').downcase
      return false if values[key]&.is_a?(Numeric)
      true
    end
  end
end
