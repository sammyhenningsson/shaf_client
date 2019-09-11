require 'json'

class ShafClient
  class Field
    attr_reader :name, :prompt, :required, :read_only,
      :hidden, :templated, :type, :value, :regex

    def initialize(
      name:,
      prompt: nil,
      title: nil,
      required: false,
      read_only: false,
      hidden: false,
      templated: false,
      type: nil,
      value: nil,
      regex: nil
    )
      @name = name.to_sym
      @prompt = prompt || title || name
      @required = required
      @read_only = read_only
      @hidden = hidden
      @templated = templated
      @type = type&.downcase
      @value = value
      @regex = parse_regexp(regex)
    end

    def valid?(value)
      return false unless validate_required(value)
      return false unless validate_number(value)
      return false unless validate_string(value)
      return false unless validate_regexp(value)
      true
    end

    private

    def validate_required(value)
      return true unless required
      return false if String(value).empty?
      true
    end

    def validate_number(value)
      return true if value.nil?
      return true unless type
      return true unless %w[int integer number].include? type
      value.is_a? Numeric
    end

    def validate_string(value)
      return true if value.nil?
      return true unless type
      return true unless %w[string text].include? type
      value.is_a? String
    end

    def validate_regexp(value)
      str = String(value)
      return true if str.empty?
      return true unless regex
      str.match? regex
    end

    def parse_regexp(str)
      return if String(str).empty?
      Regexp.new(str)
    rescue RegexpError
      nil
    end
  end
end
