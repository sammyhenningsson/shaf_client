require 'spec_helper'

# Include this module in sub classes of ShafClient::Form and assign the @form
# instance variable (with an instance of the inherited form) in the before
# hook. Example:
# 
# describe FormChild do
#   include ShafClient::FormSpec
#
#   before do
#     @form = FormChild.new(args)
#   end
# end

class ShafClient
  module FormSpec
    extend Minitest::Spec::DSL

    it '#[] and #[]=' do
      field = @form.fields.first
      _(field).wont_be_nil
      @form[field.name] = 'foo'
      _(@form[field.name]).must_equal 'foo'
    end

    it '#[] raises exception when key does not exist' do
      _(-> { @form['non-exisitng-field'] }).must_raise KeyError
    end

    it '#[]= raises exception when key does not exist' do
      _(-> { @form['non-exisitng-field'] = 'foo' }).must_raise KeyError
    end

    it '#title' do
      @form.title # wont raise
    end

    it '#target' do
      _(@form.target).wont_be_nil
    end

    it '#http_method' do
      _(@form.http_method).wont_be_nil
    end

    it '#content_type' do
      _(@form.content_type).wont_be_nil
    end

    it '#fields' do
      fields = @form.fields
      _(fields).wont_be :empty?
      fields.each do |field|
        _(field).must_be_kind_of(Field)
      end
    end

    it '#submit' do
      method = @form.http_method.downcase.to_sym
      stubs.send(method, @form.target) do
        [201, {'Content-Type' => 'text/plain'}, 'done']
      end

      response = @form.submit

      _(response.body).must_equal 'done'
    end
  end
end
