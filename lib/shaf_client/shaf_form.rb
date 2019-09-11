require 'shaf_client/form'

class ShafClient
  class ShafForm < Form

    profile 'shaf-form'

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
        Field.new(values.transform_keys(&:to_sym))
      end
    end
  end
end
