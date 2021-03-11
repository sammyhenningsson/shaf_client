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

module ResourceMapperCleaner
  def reset_content_type_mapping(&block)
    mapping = ShafClient::ResourceMapper.instance_variable_get(:@mapping)
    registered_content_types = mapping.keys

    block&.call

    (mapping.keys - registered_content_types).each do |key|
      mapping.delete(key)
    end
  end
end

ShafClient.prepend Stubbing

class ClientSpec < Minitest::Spec
  include Minitest::Hooks
  include TestDataHelper
  include ResourceMapperCleaner

  around do |&block|
    reset_content_type_mapping { super(&block) }
  end

  register_spec_type(self) { true }
end


