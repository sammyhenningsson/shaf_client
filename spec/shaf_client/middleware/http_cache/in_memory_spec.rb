# frozen_string_literal: true

require 'spec_helper'

class ShafClient
  module Middleware
    class HttpCache
      describe InMemory do
        def entry(key: 'nyckel', payload: 'foobar', etag: 'gate', expire_at: Time.now + 60, vary: {})
          Entry.new(
            key: key,
            payload: payload,
            etag: etag,
            expire_at: expire_at,
            vary: vary
          )
        end

        let(:cache) { InMemory.new }
        let(:storable_entry) { entry }
        let(:unstorable_entry) { entry(payload: nil) }
        let(:expired_time) { Time.now - 10 }

        it 'stores entries when they are storable' do
          cache.size.must_equal 0
          cache.store(storable_entry)
          cache.size.must_equal 1
        end

        it 'does not store entries when they are not storable' do
          cache.size.must_equal 0
          cache.store(unstorable_entry)
          cache.size.must_equal 0
        end

        it 'is possible to clear the cache' do
          10.times do |i|
            cache.store(entry(key: "key#{i}"))
          end
          cache.size.must_equal 10

          cache.clear

          cache.size.must_equal 0
        end

        it 'is possible to clear invalid entries' do
          7.times do |i|
            cache.store(entry(key: "key#{i}"))
          end
          9.times do |i|
            cache.store(entry(key: "key1#{i}", expire_at: expired_time))
          end
          cache.size.must_equal 16

          cache.clear_invalid

          cache.size.must_equal 7
        end

        describe '#get' do
          before do
            0.upto(9) do |i|
              entry = entry(key: "invalid#{i}", expire_at: expired_time)
              cache.store(entry)
            end

            10.upto(19) do |i|
              entry = entry(key: "valid#{i}")
              cache.store(entry)
            end
          end

          it 'returns a maching entry' do
            entry = cache.get(Query.new(key: 'valid12'))
            entry.wont_be_nil
            entry.key.must_equal 'valid12'
          end

          it 'yields maching entry' do
            cache.get(Query.new(key: 'valid13')) do |entry|
              entry.wont_be_nil
              entry.key.must_equal 'valid13'
            end
          end

          it 'returns a maching entry with vary headers' do
            key = 'foobar'
            cache.store(entry(key: key, vary: {h: 'foo'}))
            cache.store(entry(key: key, vary: {h: 'bar'}))
            cache.store(entry(key: 'other', vary: {h: 'foo'}))

            found1 = cache.get(Query.new(key: key))
            found2 = cache.get(Query.new(key: key, headers: {h: 'foo'}))
            found3 = cache.get(Query.new(key: key, headers: {h: 'unknown'}))

            found1.must_be_nil
            found2.wont_be_nil
            found3.must_be_nil

            found2.key.must_equal key
            found2.vary.must_equal(h: 'foo')
          end

          it 'does not return non existing keys' do
            cache.get(Query.new(key: 'foobar')).must_be_nil
          end

          it 'does not yield non existing keys' do
            cache.get(Query.new(key: 'foobar')) do |entry|
              flunk "Cache yielded an expired entry (key=#{entry.key})"
            end
          end
        end

        describe '#put' do
          it 'can have multiple entries with the same key' do
            cache.put(entry(key: 'foo'))
            cache.put(entry(key: 'foobar', vary: {some_bar: 'bara'}))
            cache.put(entry(key: 'foobar', vary: {some_header: 'baz'}))

            cache.size.must_equal 3
          end

          it 'does not insert duplicate entries' do
            cache.put(entry(key: 'foobar', vary: {some_header: 'foo'}))
            cache.put(entry(key: 'foobar', vary: {some_header: 'foo'}))

            cache.size.must_equal 1
          end
        end
      end
    end
  end
end
