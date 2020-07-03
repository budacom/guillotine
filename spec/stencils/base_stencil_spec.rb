require "spec_helper"

RSpec.describe BaseStencil do
  describe "#initialize" do
    it "stores given match" do
      expect(described_class.new('foo').match).to eq 'foo'
    end
  end
end
