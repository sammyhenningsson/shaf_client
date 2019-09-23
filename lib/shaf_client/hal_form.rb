require 'shaf_client/form'

class ShafClient
  class HalForm < Form
    attr_accessor :target

    content_type 'application/prs.hal-forms+json'

    def title
      template[:title]
    end

    def name
      attribute(:name)
    end

    def http_method
      template[:method].downcase.to_sym
    end

    def content_type
      template[:contentType] || 'application/json'
    end

    def fields
      template[:properties].map do |values|
        Field.new(values.transform_keys(&:to_sym))
      end
    end

    private

    def template
      @template ||= attributes
        .dig(:_templates, 'default')
        .transform_keys(&:to_sym)
    end
  end
end
