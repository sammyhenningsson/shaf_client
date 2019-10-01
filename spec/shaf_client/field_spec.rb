require 'spec_helper'

class ShafClient
  describe Field do
    it 'can validate number' do
      field = Field.new(name: 'foo', type: 'integer')

      _(field.valid?(2)).must_equal true
      _(field.valid?(nil)).must_equal true
      _(field.valid?("2")).must_equal false
    end

    it 'can validate strings' do
      field = Field.new(name: 'foo', type: 'string')

      _(field.valid?("2")).must_equal true
      _(field.valid?(nil)).must_equal true
      _(field.valid?(2)).must_equal false
    end

    it 'can validate strings' do
      field = Field.new(name: 'foo', required: 'true', type: 'string')

      _(field.valid?("bar")).must_equal true
      _(field.valid?("")).must_equal false
      _(field.valid?(nil)).must_equal false
    end

    it 'can validate regex' do
      field = Field.new(name: 'foo', regex: '\d-\d')

      _(field.valid?("2-3")).must_equal true
      _(field.valid?(nil)).must_equal true
      _(field.valid?("")).must_equal true
      _(field.valid?("22")).must_equal false
    end
  end
end
