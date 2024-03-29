require 'shaf_client'
require 'shaf_client/test/stubbing'
require 'minitest/autorun'
require 'minitest/hooks'

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

ShafClient.prepend ShafClient::Test::Stubbing

class ClientSpec < Minitest::Spec
  include Minitest::Hooks
  include TestDataHelper
  include ResourceMapperCleaner

  let(:client) { ShafClient.new('https://a.io', faraday_adapter: :test) }
  let(:stubs) { client.stubs }

  around do |&block|
    reset_content_type_mapping { super(&block) }
  end

  register_spec_type(self) { true }
end
