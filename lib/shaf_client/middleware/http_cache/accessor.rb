# frozen_string_literal: true

class ShafClient
  module Middleware
    class HttpCache
      module Accessor
        module Accessible
          extend Forwardable
          def_delegator :__cache, :size, :cache_size
          def_delegator :__cache, :clear, :clear_cache
          def_delegator :__cache, :clear_stale, :clear_stale_cache
        end

        def self.for(cache)
          block = proc { cache }

          Module.new do
            include Accessible
            define_method(:__cache, &block)
          end
        end
      end
    end
  end
end
