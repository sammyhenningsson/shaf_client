require 'shaf_client/error'
require 'shaf_client/content_type_map'
require 'shaf_client/resource_extension'

class ShafClient
  module ResourceMapper
    class << self
      def for(content_type:, headers: {}, payload: nil, client: nil)
        content_type = content_type&.to_sym
        profile = profile_from(content_type, headers, payload)
        clazz, extensions = result_for(content_type, payload, profile, client)

        raise_unsupported_error(content_type) unless clazz

        [clazz, extensions]
      end

      def register(content_type, profile = nil, clazz)
        mapping[content_type&.to_sym, profile] = clazz
      end

      def unregister(content_type, profile = nil)
        mapping.delete(content_type.to_sym, profile)
      end

      def default=(clazz)
        mapping.default = clazz
      end

      private

      def mapping
        @mapping ||= ContentTypeMap.new
      end

      def result_for(content_type, payload, profile, client)
        clazz = nil
        extensions = []

        # Note: mapping typically has a default value, so we need to check that the key really exist
        if mapping.key? content_type, profile
          # Registered classes with profile takes precedence over linked profiles
          clazz = mapping[content_type, profile]
        else
          clazz = mapping[content_type]
          extensions = extensions_for(clazz, profile, payload, client) if profile
        end

        [clazz, extensions]
      end

      def profile_from(content_type, headers, payload)
        profile_from_content_type(content_type) ||
          profile_from_link_header(headers) ||
          profile_from_payload_link(content_type, payload)
      rescue StandardError => err
        warn "Exception while looking up profile link relation: #{err}"
      end

      def profile_from_content_type(content_type)
        return unless content_type

        content_type[/profile="?([^"\s;]*)/, 1]
      end

      def profile_from_link_header(headers)
        links = String(headers["link"] || headers["Link"]).split(',')
        profile_link = links.find { |link| link.match?(/rel="?profile"?/) }
        profile_link[/<(.*)>/, 1] if profile_link
      end

      def profile_from_payload_link(content_type, payload)
        clazz = mapping[content_type]
        resource = clazz&.new(nil, payload)
        return unless resource.respond_to? :link

        link = resource.link(:profile) { nil }
        link&.href
      end

      def extensions_for(clazz, profile, payload, client)
        return [] unless clazz && profile && client

        profile_resource = fetch_profile(profile, client)
        link_relations = clazz.new(nil, payload).actions if payload

        ResourceExtension.for(profile_resource, clazz, link_relations, client)
      rescue StandardError => err
        warn "Exception while resolving extensions for profile " \
          "#{profile_resource&.name || profile}: #{err}"
        []
      end

      def fetch_profile(profile, client)
        return unless profile&.start_with? %r{https?://}

        client.get(profile)
      end

      def raise_unsupported_error(content_type)
        raise UnSupportedContentType, "Can't handle Content-Type: #{content_type}"
      end
    end
  end
end
