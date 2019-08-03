# frozen_string_literal: true

class ShafClient
  module Middleware
    class HttpCache
      class MockEntry
        attr_accessor :key, :storable, :valid

        def initialize(key: 'nyckel', storable: true, valid: true)
          @key = key
          @storable = storable
          @valid = valid
        end

        def valid?(**)
          @valid
        end

        alias storable? storable
      end
    end
  end
end
