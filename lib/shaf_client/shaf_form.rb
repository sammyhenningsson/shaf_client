require 'shaf_client/form'

class ShafClient
  class ShafForm < Form

    profile 'shaf-form' #  Legacy profiles
    profile 'urn:shaf:form' # New style. Shaf version >= 2.1.0

    def title
      attribute(:title)
    end

    def name
      attribute(:name)
    end

    def target
      attribute(:href)
    end

    def http_method
      attribute(:method).downcase.to_sym
    end

    def content_type
      attribute(:type)
    end

    def fields
      attribute(:fields).map do |values|
        Field.new(**values.transform_keys(&:to_sym))
      end
    end
  end
end
