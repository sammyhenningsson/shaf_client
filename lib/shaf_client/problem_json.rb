require 'shaf_client/form'
require 'shaf_client/status_codes'

class ShafClient
  class ProblemJson < Resource
    include StatusCodes

    content_type MIME_TYPE_PROBLEM_JSON

    def type
      attribute(:type) { 'about:blank' }
    end

    def title
      attribute(:title) do
        next unless type == 'about:blank'

        StatusCode[status] if (400..599).include? status.to_i
      end
    end

    def status
      attribute(:status) { http_status }
    end

    def detail
      attribute(:detail)
    end

    def instance
      attribute(:instance)
    end

    def to_h
      attributes
    end
  end
end
