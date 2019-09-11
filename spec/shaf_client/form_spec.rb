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

    let(:http_method) { 'POST' }
    let(:client) { Minitest::Mock.new }

    it '#[] and #[]=' do
      field = @form.fields.first
      field.wont_be_nil
      @form[field.name] = 'foo'
      @form[field.name].must_equal 'foo'
    end

    it '#[] raises exception when key does not exist' do
      -> { @form['non-exisitng-field'] }.must_raise KeyError
    end

    it '#[]= raises exception when key does not exist' do
      -> { @form['non-exisitng-field'] = 'foo' }.must_raise KeyError
    end

    it '#title' do
      @form.title # wont raise
    end

    it '#target' do
      @form.target.wont_be_nil
    end

    it '#http_method' do
      @form.http_method.wont_be_nil
    end

    it '#content_type' do
      @form.content_type.wont_be_nil
    end

    it '#fields' do
      fields = @form.fields
      fields.wont_be :empty?
      fields.each do |field|
        field.must_be_kind_of(Field)
      end
    end

    it '#submit' do
      method = http_method.downcase.to_sym
      client.expect method, nil do |target, **kwargs|
        next unless target == @form.target
        next unless kwargs[:payload]
        next unless kwargs[:headers]['Content-Type'] == @form.content_type
        true
      end

      @form.submit

      client.verify
    end
  end
end
