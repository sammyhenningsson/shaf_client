require 'json'
require 'shaf_client/link'

class ShafClient
  class ApiError < Resource

    profile 'shaf-error'

    def title
      attribute(:title)
    end

    def code
      attribute(:code)
    end

    def fields
      attribute(:fields)
    end
  end
end
