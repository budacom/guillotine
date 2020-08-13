require "spec_helper"

RSpec.describe ExampleFrontStencil do
  let(:read_words) do
    Shear::WordCollection.new.tap do |w|
      w.push_word('Document', bounding_box: [[210, 27], [401, 114], [385, 150], [193, 63]])
      w.push_word('country', bounding_box: [[169, 122], [248, 159], [234, 189], [155, 152]])
      w.push_word('number', bounding_box: [[120, 211], [205, 246], [194, 272], [109, 237]])
      w.push_word('ID', bounding_box: [[588, 208], [603, 214], [594, 236], [579, 230]])
      w.push_word('897.156.756', bounding_box: [[414, 338], [551, 397], [539, 425], [402, 366]])
    end
  end

  let(:stencil_match) do
    described_class.match read_words
  end

  it "matches succesfully" do
    expect(stencil_match).not_to be nil
  end

  it "reads the fields" do
    expect(stencil_match.number).to eq "897.156.756"
    expect(stencil_match.parsed_number).to eq 897156756
  end

  it "returns the stencils face" do
    expect(stencil_match.face).to eq :front
  end

  describe "#parse_number" do
    let(:example_front_stencil) { described_class.new('foo') }

    context "when number is not splittable by 3" do
      it "returns nil" do
        expect(example_front_stencil.send(:parse_number, "123.123.343.654")).to eq nil
        expect(example_front_stencil.send(:parse_number, "123523.344")).to eq nil
      end
    end

    context "when number has text in between" do
      it "returns nil" do
        expect(example_front_stencil.send(:parse_number, "647.64b.375")).to eq nil
      end
    end

    context "when number is correctly formatted" do
      it "returns the number" do
        expect(example_front_stencil.send(:parse_number, "647.645.375")).to eq 647645375
      end
    end
  end
end
