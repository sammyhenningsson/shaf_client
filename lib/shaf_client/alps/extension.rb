require 'shaf_client/alps/extension'

class ShafClient
  module Alps
    class Extension
      attr_reader :id, :href, :value

      def initialize(id:, href: nil, value: nil)
        @id = id.to_sym
        @href = href
        @value = value
      end

      def to_h
        {
          id: id,
          href: href,
          value: value,
        }
      end

      private

      def method_missing(method_name, *args, &block)
        name = method_name.to_s
        return super unless name.end_with? '?'

        id.to_s == name[0..-2]
      end

      def respond_to_missing?(method_name, include_private = false)
        return true if method_name.to_s.end_with? '?'
        super
      end
    end
  end
end
