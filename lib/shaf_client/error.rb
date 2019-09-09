class ShafClient
  class Error < StandardError; end

  class AmbiguousRelError; end
  class UnSupportedContentType < Error; end
end
