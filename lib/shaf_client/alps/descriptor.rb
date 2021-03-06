require 'shaf_client/alps/extension'

class ShafClient
  module Alps
    class Descriptor
      attr_reader :id, :href, :name, :type, :doc, :ext

      def initialize(id:, **kwargs)
        @id   = id.to_sym
        @href = kwargs[:href]
        @name = kwargs[:name]
        @type = kwargs[:type]
        @doc  = kwargs[:doc]
        @ext  = parse_extentions(kwargs[:ext])
      end

      alias extensions ext

      def to_h
        {
          id: id,
          href: href,
          name: name,
          type: type,
          doc: doc,
          ext: extensions.map(&:to_h),
        }
      end

      def semantic?
        type == 'semantic'
      end

      def safe?
        type == 'safe'
      end

      def idempotent?
        type == 'idempotent'
      end

      def unsafe?
        type == 'unsafe'
      end

      def extension(id)
        extensions.find { |ext| ext.id == id.to_sym }
      end

      private

      def parse_extentions(extensions)
        extensions ||= []
        extensions = [extensions] unless extensions.is_a? Array
        extensions.map { |ext| Extension.new(**ext.transform_keys(&:to_sym)) }
      end
    end
  end
end

