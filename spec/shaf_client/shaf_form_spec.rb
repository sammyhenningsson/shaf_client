require 'spec_helper'
require 'shaf_client/form_spec'

class ShafClient
  describe ShafForm do
    include FormSpec

    let(:http_method) { 'POST' }
    let(:form) do
      ShafClient::ShafForm.new(
        client,
        {
          method: http_method,
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

    before do
      @form = form
    end

    it '#title' do
      _(form.title).must_equal 'Create Post'
    end

    it '#name' do
      _(form.name).must_equal 'create-post'
    end

    it '#target' do
      _(form.target).must_equal '/posts'
    end

    it '#http_method' do
      _(form.http_method).must_equal :post
    end

    it '#content_type' do
      _(form.content_type).must_equal 'application/json'
    end

    it '#valid? returns true when form is valid' do
      form[:foo] = 'hello'
      form[:bar] = 'world'
      form[:baz] = 3

      _(form).must_be :valid?
    end
  end
end
