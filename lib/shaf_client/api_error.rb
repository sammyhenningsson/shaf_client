require 'json'
require 'shaf_client/link'

class ShafClient
  class ApiError < Resource

    profile 'shaf-error' # Legacy profiles
    profile 'urn:shaf:error' # New style. Shaf version >= 2.1.0

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
