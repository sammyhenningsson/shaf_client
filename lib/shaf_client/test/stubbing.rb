class ShafClient
  module Test
    module Stubbing
      def stubs
        return unless @adapter == :test
        @stubs ||= Faraday::Adapter::Test::Stubs.new
      end

      def adapter_args
        args = super
        args << stubs if @adapter == :test
        args 
      end
    end
  end
end
