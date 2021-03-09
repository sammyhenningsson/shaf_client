require 'shaf_client'
require 'minitest/autorun'
require 'minitest/hooks'

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

module TestDataHelper
  def fixture_file(name)
    file = File.join(__dir__, 'data', name)
    _(File.exist?(file)).must_equal true

    File.read(file)
  end
end

ShafClient.prepend Stubbing

class ClientSpec < Minitest::Spec
  include Minitest::Hooks
  include TestDataHelper

  around do |&block|
    mapping = ShafClient::ResourceMapper.instance_variable_get(:@mapping)
    registered_content_types = mapping.keys
    super(&block)
    leaked_content_types = mapping.keys - registered_content_types

    _(leaked_content_types).must_be_empty
  end

  register_spec_type(self) { true }
end


