# frozen_string_literal: true

require 'shaf_client/middleware/http_cache/in_memory'
require 'shaf_client/middleware/http_cache/file_storage'
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
        cached_headers = entry.response_headers.transform_keys(&:to_s)
        Response.new(body: entry.payload, headers: cached_headers)
      end

      def add_etag(env, etag)
        env[:request_headers]['If-None-Match'] = etag if etag
      end

      def handle_not_modified(env, cached_entry)
        return unless env[:status] == 304

        cached_headers = cached_entry.response_headers.transform_keys(&:to_s)
        env[:body] = cached_entry.payload
        env[:response_headers] = cached_headers.merge(env[:response_headers])

        expire_at = Entry.from(env).expire_at
        cache.update_expiration(cached_entry, expire_at)
      end

      def update_cache(env)
        cache.inc_request_count
        entry = Entry.from(env)
        return unless storable?(env: env, entry: entry)

        cache.store entry
      end

      def storable?(env:, entry:)
        return false unless %i[get put].include? env[:method]
        return false unless env[:status] != 204
        return false unless (200..299).cover? env[:status]
        return false unless entry.etag || entry.expire_at

        request_headers = env.request_headers.transform_keys { |k| k.downcase.to_sym }
        entry.vary.keys.all? do |key|
          # The respose that we see is already decoded (e.g. gunzipped) so we shouldn't need
          # to care about the Accept-Encoding header
          next true if key == :'accept-encoding'
          request_headers.include? key
        end
      end
    end
  end
end
