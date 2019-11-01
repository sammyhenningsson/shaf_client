require 'shaf_client/error'

class ShafClient
  class ResourceMapper
    class << self
      def for(content_type)
        mapping[content_type&.to_sym].tap do |clazz|
          next if clazz
          raise UnSupportedContentType,
            "Can't handle Content-Type: #{content_type}"
        end
      end

      def register(content_type, clazz)
        mapping[content_type&.to_sym] = clazz
      end

      def unregister(content_type)
        mapping.delete(content_type.to_sym)
      end

      def default=(clazz)
        mapping.default = clazz
      end

      private

      def mapping
        @mapping ||= {}
      end
    end
  end
end
