class ShafClient
  class Error < StandardError; end

  class AmbiguousRelError; end

  class UnSupportedContentType < Error
    def initialize(content_type)
      super("Can't handle Content-Type: #{content_type}")
    end
  end
end
