require "spec_helper"

RSpec.describe Guillotine::TemplateMatch do
  let(:template_match) { described_class.new('foo', 'bar', 'foo', 'bar') }

  it "does not fail" do
    expect { template_match }.not_to raise_error
  end
end
