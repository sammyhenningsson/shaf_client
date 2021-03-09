require 'set'

class ShafClient
  module ResourceExtension
    class << self
      def register(extender)
        extenders << extender
      end

      def unregister(extender)
        extenders.delete(extender)
      end

      def for(profile, base, link_relations, client)
        link_relations = remove_curies(link_relations)
        extenders.map { |extender| extender.call(profile, base, link_relations, client) }
          .compact
      end

      private

      def extenders
        @extenders ||= Set.new
      end

      def remove_curies(link_relations)
        Array(link_relations).map do |rel|
          rel.to_s.sub(/[^:]*:/, '').to_sym
        end
      end
    end
  end
end

require 'shaf_client/resource_extension/base'
require 'shaf_client/resource_extension/alps_http_method'
