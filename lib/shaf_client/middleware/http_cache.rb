# frozen_string_literal: true

require 'shaf_client/middleware/http_cache/in_memory'
require 'shaf_client/middleware/http_cache/query'
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
        cached_entry = nil

        if cacheable?(env)
          query = Query.from(env)
          cache.load(query) do |cached|
            return cached_response(cached) if cached.valid? && !skip_cache
            add_etag(env, cached.etag)
            cached_entry = cached
          end
        end

        @app.call(env).on_complete do
          handle_not_modified(env, cached_entry)
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

      def handle_not_modified(env, cached_entry)
        return unless env[:status] == 304

        env[:body] = cached_entry.payload

        expire_at = Entry.from(env).expire_at
        cache.update_expiration(cached_entry, expire_at)
      end

      def update_cache(env)
        cache.inc_request_count
        return unless storable? env

        cache.store Entry.from(env)
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
    end
  end
end
