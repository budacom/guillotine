require "spec_helper"

RSpec.describe ExampleBackStencil do
  let(:read_words) do
    Guillotine::WordCollection.new.tap do |w|
      w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
      w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]])
      w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
      w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
      w.push_word('ID', bounding_box: [[178, 421], [178, 439], [145, 439], [145, 421]])
      w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
      w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
    end
  end

  let(:stencil_match) do
    described_class.match read_words
  end

  it "matches succesfully" do
    expect(stencil_match).not_to be nil
  end

  it "reads the fields" do
    expect(stencil_match.names).to eq "John"
    expect(stencil_match.surnames).to eq "Smith Williams"
  end

  it "returns the stencils face" do
    expect(stencil_match.face).to eq :back
  end

  it "uses the overriten default_max_error for match" do
    expect(described_class.default_max_error).to eq 10
  end
end
