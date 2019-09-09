require 'shaf_client/error'

class ShafClient
  class ResourceMapper
    class << self
      def all
        @all ||= {}
      end

      def for(content_type)
        all[content_type&.to_sym].tap do |clazz|
          next if clazz
          raise UnSupportedContentType,
            "Can't handle Content-Type: #{content_type}"
        end
      end

      def register(content_type, clazz)
        all[content_type&.to_sym] = clazz
      end

      def default=(clazz)
        all.default = clazz
      end
    end
  end
end
