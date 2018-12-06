require 'spec_helper'


describe ShafClient do
  it "does not crash" do
    client = ShafClient.new('http://foo.bar')
  end
end

