# frozen_string_literal: true

require 'shaf_client/middleware/http_cache/base'

##### FIXME: cache values should be arrays!!!!!!!!

class ShafClient
  module Middleware
    class HttpCache
      class InMemory < Base
        def size
          mutex.synchronize { cache.size }
        end

        def clear
          mutex.synchronize { @cache = {} }
        end

        def clear_invalid
          mutex.synchronize do
            cache.keep_if { |_key, entry| entry.valid? }
          end
        end

        def get(entry)
          mutex.synchronize { cache[entry.key].clone }
        end

        def put(entry)
          mutex.synchronize { cache[entry.key] = entry }
        end

        private

        def mutex
          @mutex ||= Mutex.new
        end

        def cache
          @cache ||= {}
        end

        def delete_if(&block)
          mutex.synchronize do
            cache.delete_if(&block)
          end
        end
      end
    end
  end
end
