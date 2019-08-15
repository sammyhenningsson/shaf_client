require 'spec_helper'

describe ShafClient::Form do
  let(:client) { nil }
  let(:form) do
    ShafClient::Form.new(
      client,
      {
        method: 'POST',
        name: 'create-post',
        title: 'Create Post',
        href: '/posts',
        type: 'application/json',
        _links: {
          self: {
            href: 'http://localhost:3000/posts/form'
          }
        },
        fields: [
          {
            'name' => 'foo',
            'type' => 'string'
          },
          {
            'name' => 'bar',
            'type' => 'string',
            'required' => true
          },
          {
            'name' => 'baz',
            'type' => 'integer'
          }
        ]
      }
    )
  end

  describe '#valid?' do
    it 'returns true when form is valid' do
      form[:foo] = 'hello'
      form[:bar] = 'world'
      form[:baz] = 3

      form.must_be :valid?
    end

    it 'only requires required fields to be filled' do
      form[:bar] = 'world'

      form.must_be :valid?
    end

    it 'returns false when an integer is assigned to a string field' do
      form[:foo] = 5
      form[:bar] = 'world'

      form.wont_be :valid?
    end

    it 'returns false when a string is assigned to an integer field' do
      form[:bar] = 'world'
      form[:baz] = '4'

      form.wont_be :valid?
    end
  end
end
