require 'spec_helper'

describe ShafClient::BaseResource do
  it 'parses attributes from string' do
    payload = JSON.generate(
      foo: 'foo',
      bar: 2,
      baz: %w[a b c]
    )
    resource = ShafClient::BaseResource.new(payload)

    _(resource.attributes.size).must_equal 3
    _(resource.attribute(:foo)).must_equal 'foo'
    _(resource.attribute(:bar)).must_equal 2
    _(resource.attribute(:baz)).must_equal %w[a b c]
    _ { resource.attribute(:not_present) }.must_raise ShafClient::Error
    _(resource.attribute(:not_present) { 'hello' }).must_equal 'hello'
    _(resource.links).must_be_empty
    _(resource.embedded_resources).must_be_empty
  end

  it 'parses attributes from hash' do
    payload = {
      foo: 'foo',
      bar: 2,
      baz: %w[a b c]
    }
    resource = ShafClient::BaseResource.new(payload)

    _(resource.attributes.size).must_equal 3
    _(resource.attribute(:foo)).must_equal 'foo'
    _(resource.attribute(:bar)).must_equal 2
    _(resource.attribute(:baz)).must_equal %w[a b c]
  end

  it 'parses links' do
    payload = JSON.generate(
      _links: {
        self: { href: '/self' },
        other: { href: '/other' }
      }
    )
    resource = ShafClient::BaseResource.new(payload)

    _(resource.links.size).must_equal 2
    _(resource.link(:self)).must_be_instance_of ShafClient::Link
    _(resource.link(:self).href).must_equal '/self'
    _(resource.link(:self)).wont_be :templated?
    _(resource.link(:other)).must_be_instance_of ShafClient::Link
    _(resource.link(:other).href).must_equal '/other'
    _(resource.link(:other)).wont_be :templated?

    _ { resource.link(:none) }.must_raise ShafClient::Error
    _(resource.link(:none) { 'hello' }).must_equal 'hello'

    _(resource.attributes).must_be_empty
  end

  it 'parses links in array' do
    payload = JSON.generate(
      _links: {
        self: { href: '/self' },
        other: [
          { href: '/other1' },
          { href: '/other2' }
        ]
      }
    )
    resource = ShafClient::BaseResource.new(payload)

    _(resource.link(:other).size).must_equal 2
    link1, link2 = resource.link(:other)
    _(link1).must_be_instance_of ShafClient::Link
    _(link1.href).must_equal '/other1'
    _(link1).wont_be :templated?
    _(link2).must_be_instance_of ShafClient::Link
    _(link2.href).must_equal '/other2'
    _(link2).wont_be :templated?
  end

  it 'parses curies' do
    payload = JSON.generate(
      _links: {
        curies: [
          {
            name: 'doc',
            href: '/documentation/{rel}',
            templated: true
          }
        ],
        'doc:other': { href: '/other' }
      }
    )
    resource = ShafClient::BaseResource.new(payload)

    _(resource.links.size).must_equal 1
    _(resource.curies.size).must_equal 1
    curie = resource.curie(:doc)
    _(curie).must_be_instance_of ShafClient::Curie
    _(curie.href).must_equal '/documentation/{rel}'
    _(curie).must_be :templated?
    _(curie.resolve_templated(rel: 'doc:other')).must_equal '/documentation/other'
    _(curie.resolve_templated(rel: 'other')).must_equal '/documentation/other'

    _ { resource.curie(:none) }.must_raise ShafClient::Error
    _(resource.curie(:none) { 'hello' }).must_equal 'hello'
  end

  it 'parses embedded reources' do
    payload = JSON.generate(
      _embedded: {
        newest_item: {
          id: 2,
          name: 'item2'
        },
        items: [
          {
            id: 1,
            name: 'item1'
          },
          {
            id: 2,
            name: 'item2'
          }
        ]
      }
    )
    resource = ShafClient::BaseResource.new(payload)

    item = resource.embedded(:newest_item)
    _(item).must_be_instance_of ShafClient::BaseResource
    _(item.id).must_equal 2
    _(item.name).must_equal 'item2'

    _(resource.embedded_resources.size).must_equal 2
    items = resource.embedded(:items)
    _(items).must_be_instance_of Array
    _(items.first.id).must_equal 1
    _(items.last.name).must_equal 'item2'

    _ { resource.embedded(:none) }.must_raise ShafClient::Error
    _(resource.embedded(:none) { 'hello' }).must_equal 'hello'
  end

  it '#<<' do
    payload1 = JSON.generate(
      a: 'one',
      b: 1,
      _links: {
        self: { href: '/one' }
      },
      _embedded: {
        item: {
          c: 'first'
        }
      }
    )
    resource1 = ShafClient::BaseResource.new(payload1)

    payload2 = JSON.generate(
      a: 'two',
      b: 2,
      _links: {
        self: { href: '/two' }
      },
      _embedded: {
        item: {
          c: 'second'
        }
      }
    )
    resource2 = ShafClient::BaseResource.new(payload2)

    resource2.send(:<<, resource1)

    _(resource2.attribute(:a)).must_equal('one')
    _(resource2.attribute(:b)).must_equal(1)
    _(resource2.link(:self).href).must_equal('/one')
    _(resource2.embedded(:item).attribute(:c)).must_equal('first')
  end

  it '#rel?' do
    payload = JSON.generate(
      a: 'one',
      b: 1,
      _links: {
        self: { href: '/one' },
        'foo-bar': { href: '/foo' }
      }
    )
    resource = ShafClient::BaseResource.new(payload)
    assert resource.rel? :self
    assert resource.rel? 'self'
    assert resource.rel? :'foo-bar'
    assert resource.rel? :foo_bar
    assert resource.rel? 'foo-bar'

    refute resource.rel? 'foo'
    refute resource.rel? :foo
  end
end
