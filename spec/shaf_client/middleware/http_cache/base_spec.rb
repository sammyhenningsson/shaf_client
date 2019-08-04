# frozen_string_literal: true

require 'spec_helper'

class ShafClient
  module Middleware
    class HttpCache
      describe Base do
        let(:cache) { InMemory.new }

        def entry(key)
          Entry.new(key: key, payload: 'foobar', etag: 'gate')
        end

        it 'can be initialized without args' do
          InMemory.new.wont_be_nil
        end

        it 'can be initialized with keyword args' do
          InMemory.new(foo: 'bar').wont_be_nil
        end

        describe '#purge' do
          before do
            25.times do |i|
              cache.store(entry("key#{i}"))
            end
          end

          it 'purges entries when above threshold' do
            cache.purge_threshold = 20
            cache.send(:purge)
            cache.size.must_equal 16
          end

          it 'does not purge entries when below threshold' do
            cache.purge_threshold = 30
            cache.send(:purge)
            cache.size.must_equal 25
          end
        end
      end
    end
  end
end
