require 'spec_helper'

describe ShafClient::Link do
  describe '#resolve' do
    it 'resolves a templated link' do
      link = ShafClient::Link.new(href: '/foo/{bar}', templated: true)
      _(link.resolve_templated(bar: 5)).must_equal '/foo/5'
    end

    it 'resolves multiple' do
      link = ShafClient::Link.new(href: '/foo/{bar}/{baz}', templated: true)
      _(link.resolve_templated(bar: 'items', baz: 7)).must_equal '/foo/items/7'
    end

    it 'raises an exception when required argument is not provided' do
      link = ShafClient::Link.new(href: '/foo/{bar}', templated: true)
      _(proc { link.resolve_templated(foo: 5) }).must_raise ArgumentError
    end

    it 'resolves a optional variables' do
      link = ShafClient::Link.new(href: '/foo{?foo,bar}', templated: true)
      _(link.resolve_templated(foo: 'aa', bar: 5)).must_equal '/foo?foo=aa&bar=5'
    end

    it 'resolves a combination of both required and optional variables' do
      link = ShafClient::Link.new(href: '/foo/{rel}{?foo,bar}', templated: true)
      _(link.resolve_templated(rel: 'item', bar: 'hi')).must_equal '/foo/item?bar=hi'
    end

    it 'resolves a link when optional variables are not provided' do
      link = ShafClient::Link.new(href: '/foo{?foo,bar}', templated: true)
      _(link.resolve_templated).must_equal '/foo'
    end

    it 'returns href when link is not templated' do
      link = ShafClient::Link.new(href: '/foo/bar')
      _(link.resolve_templated).must_equal '/foo/bar'
    end
  end
end
