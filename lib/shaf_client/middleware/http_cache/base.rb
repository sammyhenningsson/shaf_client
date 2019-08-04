require 'shaf_client/middleware/http_cache/entry'
require 'shaf_client/middleware/http_cache/key'

class ShafClient
  module Middleware
    class HttpCache
      class Base
        DEFAULT_PURGE_THRESHOLD         = 1000
        DEFAULT_NO_REQUEST_BETWEEN_PURGE = 500

        attr_writer :request_count, :purge_threshold

        def initialize(**_options); end

        def purge_threshold
          @purge_threshold ||= DEFAULT_PURGE_THRESHOLD
        end

        def requests_between_purge
          DEFAULT_NO_REQUEST_BETWEEN_PURGE
        end

        def should_purge?
          (request_count % requests_between_purge).zero?
        end

        def inc_request_count
          self.request_count += 1
          return unless should_purge?

          clear_invalid
          purge
        end

        def request_count
          @request_count ||= 0
        end

        def purge_target
          (purge_threshold * 0.8).to_i
        end

        def purge
          return unless size > purge_threshold

          count = size - purge_target
          return unless count.positive?

          delete_if do
            break if count.zero?
            count -= 1
          end
        end

        def load(query)
          entry = get(query)
          return entry unless block_given?
          yield entry if entry
        end

        def store(entry)
          return unless entry.storable?
          put(entry)
        end

        def update_expiration(entry, expire_at)
          return unless expire_at

          updated_entry = entry.dup
          updated_entry.expire_at = expire_at
          store(updated_entry)
        end

        %i[size get put clear clear_invalid delete_if].each do |name|
          define_method(name) do
            raise NotImplementedError, "#{self.class} does not implement required method #{name}"
          end
        end

        private :delete_if
      end
    end
  end
end
