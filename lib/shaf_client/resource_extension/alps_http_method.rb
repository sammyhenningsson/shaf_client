class ShafClient
  module ResourceExtension
    class AlpsHttpMethod < Base
      class << self
        def call(profile, base, link_relations, _client)
          return unless profile.is_a? AlpsJson
          return unless base <= Resource

          link_relations = Array(link_relations).compact
          descriptors = descriptors_with_http_method(profile)
          descriptors.keep_if do |descriptor|
            link_relations.include? identifier_for(descriptor)&.to_sym
          end

          extension_for(descriptors)
        end

        private

        def descriptors_with_http_method(profile)
          profile.each_descriptor.each_with_object([]) do |descriptor, descriptors|
            next unless descriptor.extension(:http_method)
            descriptors << descriptor
          end
        end

        def extension_for(descriptors)
          return if descriptors.empty?

          Module.new.tap do |mod|
            descriptors.each do |descriptor|
              add_method(mod, descriptor, methods.first)
            end
          end
        end

        def add_method(mod, descriptor, method)
          rel = identifier_for(descriptor)
          return unless rel

          ext = descriptor.extension(:http_method)
          methods = Array(ext&.value)

          # We only know what method to use when size is 1
          return unless methods.size == 1

          http_method = methods.first.downcase.to_sym
          name = method_name_from(rel)

          mod.define_method(name) do |payload: nil, **options|
            href = link(rel).href
            client.send(http_method, href, payload: payload, **options)
          end
        end

        def method_name_from(rel)
          "#{rel.to_s.downcase.tr('-', '_')}!"
        end

        def identifier_for(descriptor)
          # Currently we only support `id` (i.e no support for descriptors with `href`)
          descriptor.id
        end
      end
    end
  end
end
