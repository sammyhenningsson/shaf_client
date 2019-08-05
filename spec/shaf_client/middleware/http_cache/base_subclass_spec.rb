# frozen_string_literal: true

class ShafClient
  module Middleware
    class HttpCache
      module BaseSubclassSpec
        def build_entries(valid: 7, invalid: 9)
          valid.times do |i|
            @cache.put(entry(key: "key#{i}"))
          end
          invalid.times do |i|
            @cache.put(entry(key: "key1#{i}", payload: nil))
          end
        end

        def entry(key: 'nyckel', payload: 'foobar', etag: 'gate', expire_at: nil, vary: {})
          Entry.new(
            key: key,
            payload: payload,
            etag: etag,
            expire_at: expire_at || Time.now + 60,
            vary: vary
          )
        end

        def test_can_be_initialized_without_args
          @cache.class.new.wont_be_nil
        end

        def test_can_be_initialized_with_keyword_args
          @cache.class.new(foo: 'bar').wont_be_nil
        end

        def test_purges_entries_when_above_threshold
          build_entries valid: 25

          @cache.purge_threshold = 20
          @cache.send(:purge)
          @cache.size.must_equal 16
        end

        def test_does_not_purge_entries_when_below_threshold
          build_entries valid: 25

          @cache.purge_threshold = 30
          @cache.send(:purge)
          @cache.size.must_equal 25
        end

        def test_stores_entries_when_they_are_storable
          @cache.size.must_equal 0
          @cache.store(entry)
          @cache.size.must_equal 1
        end

        def test_does_not_store_entries_when_they_are_not_storable
          @cache.size.must_equal 0
          @cache.store(entry(payload: nil))
          @cache.size.must_equal 0
        end

        def test_is_possible_to_clear_the_cache
          build_entries(valid: 10, invalid: 0)

          @cache.size.must_equal 10
          @cache.clear
          @cache.size.must_equal 0
        end

        def test_is_possible_to_clear_invalid_entries
          build_entries

          @cache.size.must_equal 16
          @cache.clear_invalid
          @cache.size.must_equal 7
        end

        def test_returns_a_maching_entry
          build_entries
          entry = @cache.get(Query.new(key: 'key12'))
          entry.wont_be_nil
          entry.key.must_equal 'key12'
        end

        def test_yields_maching_entry
          build_entries
          @cache.get(Query.new(key: 'key13')) do |entry|
            entry.wont_be_nil
            entry.key.must_equal 'key13'
          end
        end

        def test_returns_a_maching_entry_with_vary_headers
          key = 'foobar'
          @cache.store(entry(key: key, vary: {h: 'foo'}))
          @cache.store(entry(key: key, vary: {h: 'bar'}))
          @cache.store(entry(key: 'other', vary: {h: 'foo'}))

          found1 = @cache.get(Query.new(key: key))
          found2 = @cache.get(Query.new(key: key, headers: {h: 'foo'}))
          found3 = @cache.get(Query.new(key: key, headers: {h: 'unknown'}))

          found1.must_be_nil
          found2.wont_be_nil
          found3.must_be_nil

          found2.key.must_equal key
          found2.vary.must_equal(h: 'foo')
        end

        def test_does_not_return_non_existing_keys
          build_entries
          @cache.get(Query.new(key: 'foobar')).must_be_nil
        end

        def test_does_not_return_invalid_entries
          build_entries
          @cache.get(Query.new(key: 'foobar')).must_be_nil
        end

        def test_does_not_yield_non_existing_keys
          build_entries
          @cache.get(Query.new(key: 'foobar')) do |entry|
            flunk "Cache yielded an expired entry (key=#{entry.key})"
          end
        end

        def test_can_have_multiple_entries_with_the_same_key
          @cache.put(entry(key: 'foo'))
          @cache.put(entry(key: 'foobar', vary: {some_bar: 'bara'}))
          @cache.put(entry(key: 'foobar', vary: {some_header: 'baz'}))

          @cache.size.must_equal 3
        end

        def test_does_not_insert_duplicate_entries
          @cache.put(entry(key: 'foobar', vary: {some_header: 'foo'}))
          @cache.put(entry(key: 'foobar', vary: {some_header: 'foo'}))

          @cache.size.must_equal 1
        end
      end
    end
  end
end
