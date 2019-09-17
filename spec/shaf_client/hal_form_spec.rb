require 'spec_helper'
require 'shaf_client/form_spec'
require 'json'

class ShafClient
  describe HalForm do
    include FormSpec

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
      form.title.must_equal 'Create'
    end

    it '#target' do
      form.target.must_equal '/posts'
    end

    it '#http_method' do
      form.http_method.must_equal :post
    end

    it '#content_type' do
      form.content_type.must_equal 'application/json'
    end

    it '#valid? returns true when form is valid' do
      form.wont_be :valid?
      form[:title] = 'hello'
      form.wont_be :valid?
      form[:title] = 'foobar'

      form.must_be :valid?
    end
  end
end
