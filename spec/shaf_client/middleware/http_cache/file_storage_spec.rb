# frozen_string_literal: true

require 'spec_helper'
require 'securerandom'
require 'fileutils'
require 'shaf_client/middleware/http_cache/base_subclass_spec'

class ShafClient
  module Middleware
    class HttpCache
      describe FileStorage do
        include BaseSubclassSpec

        let(:tmpdir) { "/tmp/#{SecureRandom.hex(10)}" }

        before do
          @cache = FileStorage.new(directory: tmpdir)
        end

        after do
          FileUtils.remove_entry_secure tmpdir if Dir.exist? tmpdir
        end

        it 'creates directory unless it exists' do
          File.exist?(tmpdir).must_equal(true)
        end
      end
    end
  end
end
