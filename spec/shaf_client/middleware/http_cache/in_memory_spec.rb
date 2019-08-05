# frozen_string_literal: true

require 'spec_helper'
require 'shaf_client/middleware/http_cache/base_subclass_spec'

class ShafClient
  module Middleware
    class HttpCache
      describe InMemory do
        include BaseSubclassSpec

        before do
          @cache = InMemory.new
        end
      end
    end
  end
end
