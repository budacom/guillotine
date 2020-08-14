require "spec_helper"

describe Shear do
  before do
    helper_example
  end

  it "has a version number" do
    expect(Shear::VERSION).not_to be nil
  end
end
