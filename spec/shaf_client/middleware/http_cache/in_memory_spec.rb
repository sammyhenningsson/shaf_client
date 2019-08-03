# frozen_string_literal: true

require 'spec_helper'
require 'shaf_client/middleware/http_cache/mock_entry'

class ShafClient
  module Middleware
    class HttpCache
      describe InMemory do
        let(:cache) { InMemory.new }

        it 'only stores entries when they are storable' do
          cache.size.must_equal 0
          cache.store(MockEntry.new)
          cache.size.must_equal 1
        end

        it 'only stores entries when they are storable' do
          entry = MockEntry.new(storable: false)

          cache.size.must_equal 0
          cache.store(entry)
          cache.size.must_equal 0
        end

        it 'is possible to clear the cache' do
          10.times do |i|
            cache.store(MockEntry.new(key: "key#{i}"))
          end
          cache.size.must_equal 10

          cache.clear

          cache.size.must_equal 0
        end

        it 'is possible to clear invalid entries' do
          7.times do |i|
            cache.store(MockEntry.new(key: "key#{i}", valid: true))
          end
          9.times do |i|
            cache.store(MockEntry.new(key: "key1#{i}", valid: false))
          end
          cache.size.must_equal 16

          cache.clear_invalid

          cache.size.must_equal 7
        end

        it 'does not insert duplicate entries' do
          skip '# TODO'
        end

        describe '#get' do
          let(:entries) { [] }

          before do
            0.upto(9) do |i|
              entry = MockEntry.new(key: "invalid#{i}", valid: false)
              cache.store(entry)
              entries << entry
            end

            10.upto(19) do |i|
              entry = MockEntry.new(key: "valid#{i}")
              cache.store(entry)
              entries << entry
            end
          end

          it 'returns a maching entry' do
            entry = cache.get(MockEntry.new(key: 'valid12'))
            entry.wont_be_nil
            entry.key.must_equal 'valid12'
          end

          it 'yields maching entry' do
            cache.get(MockEntry.new(key: 'valid13')) do |entry|
              entry.wont_be_nil
              entry.key.must_equal 'valid13'
            end
          end

          it 'does not return non existing keys' do
            cache.get(MockEntry.new(key: 'foobar')).must_be_nil
          end

          it 'does not return invalid entries' do
            cache.get(MockEntry.new(key: 'invalid22')).must_be_nil
          end

          it 'does not yield invalid entries' do
            cache.get(MockEntry.new(key: 'invalid23')) do |entry|
              flunk "Cache yielded an expired entry (key=#{entry.key})"
            end
          end
        end
      end
    end
  end
end
