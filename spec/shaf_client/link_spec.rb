require 'spec_helper'

describe ShafClient::Link do
  describe '#resolve' do
    it 'resolves a templated link' do
      link = ShafClient::Link.new(href: '/foo/{bar}', templated: true)
      link.resolve_templated(bar: 5).must_equal '/foo/5'
    end

    it 'returns href when link is not templated' do
      link = ShafClient::Link.new(href: '/foo/bar')
      link.resolve_templated.must_equal '/foo/bar'
    end
  end
end
