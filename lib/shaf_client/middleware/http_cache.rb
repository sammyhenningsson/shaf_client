# frozen_string_literal: true

require 'shaf_client/middleware/http_cache/in_memory'
require 'shaf_client/middleware/http_cache/accessor'

class ShafClient
  module Middleware
    class HttpCache
      Response = Struct.new(:status, :body, :headers, keyword_init: true)

      def initialize(app, cache_class: InMemory, accessed_by: nil, **options)
        @app = app
        @options = options
        @cache = cache_class.new(options)
        add_accessors_to accessed_by
      end

      def call(env)
        skip_cache = env[:request_headers].delete :skip_cache

        if cacheable?(env)
          entry = Entry.from(env)
          cache.load(entry) do |cached|
            return cached_response(cached) if cached.valid? && !skip_cache
            add_etag(env, cached.etag)
          end
        end

        @app.call(env).on_complete do
          handle_not_modified(env)
          update_cache(env)
        end
      end

      private

      attr_reader :cache

      def add_accessors_to(obj)
        return unless obj
        obj.extend Accessor.for(cache)
      end

      def cacheable?(env)
        %i[get head].include? env[:method]
      end

      def cached_response(entry)
        Response.new(body: entry.payload, headers: {})
      end

      def add_etag(env, etag)
        env[:request_headers]['If-None-Match'] = etag if etag
      end

      def handle_not_modified(env)
        return unless env[:status] == 304

        entry = Entry.from(env)
        cache.load(entry) do |cached|
          env[:body] = cached.payload
          update_expiration(cached, entry.expire_at)
        end
      end

      def update_expiration(entry, expire_at)
        return unless expire_at

        updated_entry = entry.dup
        updated_entry.expire_at = expire_at
        cache.store(updated_entry)
      end

      def update_cache(env)
        cache_response(env) if storable? env
        invalidate_cache(env) if invalidate? env

        cache.inc_request_count
      end

      def storable?(env)
        return false unless %i[get put].include? env[:method]
        return false unless env[:status] != 204
        return false unless (200..299).cover? env[:status]
        etag?(env) || max_age?(env)
      end

      def etag?(env)
        env[:response_headers].key? 'Etag'
      end

      def max_age?(env)
        cache_control = env[:response_headers].fetch('Cache-Control', '')
        cache_control =~ /\bmax-age=\d+/
      end

      def cache_response(env)
        entry = Entry.from(env)
        cache.store(entry)
      end

      def invalidate?(env)
        # FIXME !!!
      end

      def invalidate_cache(env)
        # FIXME !!!
      end
    end
  end
end
