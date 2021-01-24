require 'shaf_client'
require 'minitest/autorun'

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

ShafClient.prepend Stubbing
