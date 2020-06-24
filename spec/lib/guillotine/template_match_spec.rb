require "spec_helper"

RSpec.describe Guillotine::TemplateMatch do
  let(:collection) { described_class.new }

  it "does not fail" do
    expect { collection }.not_to raise_error
  end
end
