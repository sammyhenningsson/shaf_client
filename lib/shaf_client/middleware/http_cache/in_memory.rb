# frozen_string_literal: true

require 'shaf_client/middleware/http_cache/base'

class ShafClient
  module Middleware
    class HttpCache
      class InMemory < Base
        def size
          mutex.synchronize do
            cache.sum { |_key, entries| entries.size }
          end
        end

        def clear
          mutex.synchronize { @cache = new_hash }
        end

        def clear_invalid
          mutex.synchronize do
            cache.each do |_key, entries|
              entries.keep_if(&:valid?)
            end
          end
        end

        def get(query)
          mutex.synchronize { find(query) }
        end

        def put(entry)
          mutex.synchronize do
            existing = find(Query.from(entry))
            cache[entry.key].delete(existing) if existing
            cache[entry.key].unshift entry
          end
        end

        private

        def mutex
          @mutex ||= Mutex.new
        end

        def cache
          @cache ||= new_hash
        end

        def new_hash
          Hash.new { |hash, key| hash[key] = [] }
        end

        def delete_if(&block)
          mutex.synchronize do
            cache.each do |_key, entries|
              entries.delete_if(&block)
            end
          end
        end

        def find(query)
          cache[query.key].find { |e| query.match?(e.vary) }
        end
      end
    end
  end
end
