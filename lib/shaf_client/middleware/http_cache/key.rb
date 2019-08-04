# frozen_string_literal: true

class ShafClient
  module Middleware
    class HttpCache
      module Key
        def key(uri)
          uri = URI(uri) if uri.is_a? String
          query = (uri.query || '').split('&').sort.join('&')
          [uri.host, uri.path, query].join('_').to_sym
        end
      end
    end
  end
end
