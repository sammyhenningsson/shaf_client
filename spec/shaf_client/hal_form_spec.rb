require 'spec_helper'
require 'shaf_client/form_spec'
require 'json'

class ShafClient
  describe HalForm do
    include FormSpec

    let(:http_method) { 'POST' }
    let(:form) do
      ShafClient::HalForm.new(
        client,
        JSON.generate({
          _links: {
            self: {
              href: 'http://api.example.org/rels/create'
            }
          },
          _templates: {
            default: {
              title: 'Create',
              method: 'post',
              contentType: 'application/json',
              properties: [
                {name: 'title', required: true, value: '', prompt: 'Title', regex: 'foobar', templated: false},
                {name: 'completed', required: false, value: 'false', prompt: 'Completed', regex: ''}
              ]
            }
          }
        })
      )
    end

    before do
      @form = form.tap do |f|
        f.target = '/posts'
      end
    end

    it '#title' do
      _(form.title).must_equal 'Create'
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
      _(form).wont_be :valid?
      form[:title] = 'hello'
      _(form).wont_be :valid?
      form[:title] = 'foobar'

      _(form).must_be :valid?
    end
  end
end
