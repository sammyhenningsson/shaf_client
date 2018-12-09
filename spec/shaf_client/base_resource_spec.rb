require 'spec_helper'

describe ShafClient::BaseResource do
  it 'parses attributes from string' do
    payload = JSON.generate(
      foo: 'foo',
      bar: 2,
      baz: %w[a b c]
    )
    resource = ShafClient::BaseResource.new(payload)

    resource.attributes.size.must_equal 3
    resource.attribute(:foo).must_equal 'foo'
    resource.attribute(:bar).must_equal 2
    resource.attribute(:baz).must_equal %w[a b c]
    resource.links.must_be_empty
    resource.embedded_resources.must_be_empty
  end

  it 'parses attributes from hash' do
    payload = {
      foo: 'foo',
      bar: 2,
      baz: %w[a b c]
    }
    resource = ShafClient::BaseResource.new(payload)

    resource.attributes.size.must_equal 3
    resource.attribute(:foo).must_equal 'foo'
    resource.attribute(:bar).must_equal 2
    resource.attribute(:baz).must_equal %w[a b c]
  end

  it 'parses links' do
    payload = JSON.generate(
      _links: {
        self: { href: '/self' },
        other: { href: '/other' }
      }
    )
    resource = ShafClient::BaseResource.new(payload)

    resource.links.size.must_equal 2
    resource.link(:self).must_be_instance_of ShafClient::Link
    resource.link(:self).href.must_equal '/self'
    resource.link(:self).wont_be :templated?
    resource.link(:other).must_be_instance_of ShafClient::Link
    resource.link(:other).href.must_equal '/other'
    resource.link(:other).wont_be :templated?
    resource.attributes.must_be_empty
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

    resource.links.size.must_equal 1
    resource.curies.size.must_equal 1
    curie = resource.curie(:doc)
    curie.must_be_instance_of ShafClient::Curie
    curie.href.must_equal '/documentation/{rel}'
    curie.must_be :templated?
    curie.resolve_templated(rel: 'doc:other').must_equal '/documentation/other'
    curie.resolve_templated(rel: 'other').must_equal '/documentation/other'
  end

  it 'parses embedded reource' do
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
    item.must_be_instance_of ShafClient::BaseResource
    item.id.must_equal 2
    item.name.must_equal 'item2'

    resource.embedded_resources.size.must_equal 2
    items = resource.embedded(:items)
    items.must_be_instance_of Array
    items.first.id.must_equal 1
    items.last.name.must_equal 'item2'
  end
end
