# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'securerandom'
require 'shaf_client/middleware/http_cache/base'

class ShafClient
  module Middleware
    class HttpCache
      class FileStorage < Base
        class FileEntry < Entry
          attr_reader :filepath

          def self.deserialize(content)
            new(**JSON.parse(content, symbolize_names: true))
          end

          def self.from_entry(entry, filepath)
            new(
              key: entry.key,
              etag: entry.etag,
              expire_at: entry.expire_at,
              vary: entry.vary,
              payload: entry.payload,
              filepath: filepath,
              response_headers: entry.response_headers
            )
          end

          def initialize(
            key:,
            filepath:,
            payload: nil,
            etag: nil,
            expire_at: nil,
            vary: {},
            response_headers: {}
          )
            @filepath = filepath
            super(
              key: key,
              payload: payload,
              etag: etag,
              expire_at: expire_at,
              vary: vary,
              response_headers: response_headers
            )
          end

          def serialize
            JSON.pretty_generate(
              key: key,
              etag: etag,
              expire_at: expire_at,
              vary: vary,
              filepath: filepath,
              response_headers: response_headers,
              payload: payload
            )
          end
        end

        def initialize(**options)
          init_dir(options.delete(:directory))
        end

        def size
          count = 0
          each_file { count += 1 }
          count
        end

        def clear
          return unless Dir.exist? cache_dir

          FileUtils.remove_entry_secure cache_dir
          Dir.mkdir cache_dir
        end

        def clear_invalid
          delete_if(&:invalid?)
        end

        def get(query)
          find(query)
        end

        def put(entry)
          existing = find(Query.from(entry))
          unlink(existing) if existing
          write(entry)
        end

        def each_file
          return unless Dir.exist? cache_dir

          Dir.each_child(cache_dir) do |dir|
            Dir.each_child(File.join(cache_dir, dir)) do |file|
              yield File.join(cache_dir, dir, file)
            end
          end
        end

        def each
          each_file do |file|
            yield parse(file)
          end
        end

        private

        attr_reader :cache_dir

        def init_dir(dir)
          @cache_dir = String(dir)
          return if !@cache_dir.empty? && File.exist?(@cache_dir)

          @cache_dir = File.join(Dir.tmpdir, 'shaf_client_http_cache') if @cache_dir.empty?
          Dir.mkdir(@cache_dir) unless Dir.exist? @cache_dir
        end

        def delete_if
          each do |entry|
            unlink(entry) if yield entry
          end
        end

        def find(query)
          dir = dir(query.key)
          return unless dir && Dir.exist?(dir)

          Dir.each_child(dir) do |filename|
            path = File.join(dir, filename)
            file_entry = parse(path)
            return file_entry if query.match?(file_entry.vary)
          end
        end

        def dir(key)
          File.join(cache_dir, key.to_s.tr('/', '_'))
        end

        def parse(path)
          raise Error.new("File not readable: #{path}") unless File.readable? path

          content = File.read(path)
          FileEntry.deserialize(content)
        end

        def unlink(entry)
          File.unlink(entry.filepath) if entry.filepath
          dir = File.dirname(entry.filepath)
          Dir.delete(dir) if Dir.empty? dir
        end

        def write(entry)
          dir = dir(entry.key)
          raise Error.new("File not writable: #{dir}") unless File.writable? File.dirname(dir)
          Dir.mkdir(dir) unless Dir.exist?(dir)

          path = File.join(dir, filename(entry))
          raise Error.new("File not writable: #{dir}") unless File.writable? dir
          content = FileEntry.from_entry(entry, path).serialize
          File.write(path, content)
        end

        def filename(entry)
          [entry.expire_at, SecureRandom.hex(4)].join('_')
        end
      end
    end
  end
end
# shaf_client_http_cache
# .
# └── shaf_client_http_cache
#     ├── host_posts
#     │   ├── 2019-08-06T12:05:27_j2f
#     │   ├── 2019-08-06T10:43:10_io1
#     │   └── 2019-08-07T12:05:27_k13
#     ├── host_posts_5
#     │   └── 2019-08-07T22:12:23_kj1
#     └── host_comments
#         └── 2019-08-05T10:35:00_22m

