require "spec_helper"

RSpec.describe StencilGroup do
  let(:example_front_words) do
    Guillotine::WordCollection.new.tap do |w|
      w.push_word('Document', bounding_box: [[210, 27], [401, 114], [385, 150], [193, 63]])
      w.push_word('country', bounding_box: [[169, 122], [248, 159], [234, 189], [155, 152]])
      w.push_word('number', bounding_box: [[120, 211], [205, 246], [194, 272], [109, 237]])
      w.push_word('ID', bounding_box: [[588, 208], [603, 214], [594, 236], [579, 230]])
      w.push_word('897.156.756', bounding_box: [[414, 338], [551, 397], [539, 425], [402, 366]])
    end
  end

  let(:example_back_words) do
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

  let(:stencil_group) do
    described_class.match(stencil_map, word_collections)
  end

  context "when document has only one face" do
    let(:stencil_map) do
      { front: ExampleFrontStencil }
    end

    describe "#match" do
      context "when stencils and words match" do
        let(:word_collections) do
          {
            front: example_front_words
          }
        end

        it "returns a stencil_group instance" do
          expect(described_class.match(stencil_map, word_collections))
            .to be_an_instance_of(described_class)
        end

        it "match gives the expected stencil" do
          expect(described_class.match(stencil_map, word_collections).stencils[:front])
            .to be_an_instance_of(ExampleFrontStencil)
        end
      end

      context "when stencils and words don't match" do
        let(:word_collections) do
          {
            front: example_back_words
          }
        end

        it "returns a stencil_group instance" do
          expect(described_class.match(stencil_map, word_collections))
            .to be_an_instance_of(described_class)
        end

        it "match has a nil stencil" do
          expect(described_class.match(stencil_map, word_collections).stencils[:front]).to be nil
        end
      end

      context "when words given have extra faces" do
        let(:word_collections) do
          {
            front: example_front_words,
            back: example_back_words
          }
        end

        it "returns an instance of stencil_group" do
          expect(described_class.match(stencil_map, word_collections))
            .to be_an_instance_of(described_class)
        end

        it "there is a match for the common face" do
          expect(described_class.match(stencil_map, word_collections).stencils[:front])
            .to be_an_instance_of(ExampleFrontStencil)
        end

        it "the extra face is nil" do
          expect(described_class.match(stencil_map, word_collections).stencils[:back])
            .to be nil
        end
      end
    end

    describe "#get_attribute" do
      let(:word_collections) do
        {
          front: example_front_words
        }
      end

      it "all attributes are obtainable using the stencil_group" do
        expect(stencil_group.get_attribute("number")).to eq "897.156.756"
        expect(stencil_group.get_attribute("parsed_number")).to eq 897156756
      end

      it "fails when trying to read an attribute that is not listed on 'fields'" do
        expect { stencil_group.get_attribute("birth_date") }.to raise_error(RuntimeError)
      end
    end

    describe "#get_any?" do
      let(:word_collections) do
        {
          front: example_front_words
        }
      end

      it "returns the truth value for the field on the only stencil" do
        expect(stencil_group.get_any?("has_sensible_data?")).to eq true
      end
    end

    describe "#get_all?" do
      let(:word_collections) do
        {
          front: example_front_words
        }
      end

      it "returns the truth value for the field on the only stencil" do
        expect(stencil_group.get_all?("has_sensible_data?")).to eq true
      end
    end
  end

  context "when document has more than one face" do
    let(:stencil_map) do
      {
        front: ExampleFrontStencil,
        back: ExampleBackStencil
      }
    end

    describe "#match" do
      context "when stencils and words match" do
        let(:word_collections) do
          {
            front: example_front_words,
            back: example_back_words
          }
        end

        it "returns a stencil_group instance" do
          expect(described_class.match(stencil_map, word_collections))
            .to be_an_instance_of(described_class)
        end

        it "match gives the expected stencils" do
          expect(described_class.match(stencil_map, word_collections).stencils[:front])
            .to be_an_instance_of(ExampleFrontStencil)
          expect(described_class.match(stencil_map, word_collections).stencils[:back])
            .to be_an_instance_of(ExampleBackStencil)
        end
      end

      context "when some face fails to match" do
        let(:word_collections) do
          {
            front: example_back_words,
            back: example_back_words
          }
        end

        it "returns a stencil_group instance" do
          expect(described_class.match(stencil_map, word_collections))
            .to be_an_instance_of(described_class)
        end

        it "match has a nil stencil" do
          expect(described_class.match(stencil_map, word_collections).stencils[:front]).to be nil
        end

        it "match has a stencil for the successful match" do
          expect(described_class.match(stencil_map, word_collections).stencils[:back])
            .to be_an_instance_of(ExampleBackStencil)
        end
      end

      context "when the words from a face are missing" do
        let(:word_collections) do
          {
            front: example_front_words
          }
        end

        it "returns an instance of stencil_group" do
          expect(described_class.match(stencil_map, word_collections))
            .to be_an_instance_of(described_class)
        end

        it "there is a match for the commo face" do
          expect(described_class.match(stencil_map, word_collections).stencils[:front])
            .to be_an_instance_of(ExampleFrontStencil)
        end

        it "the face with missing words has a nil stencil" do
          expect(described_class.match(stencil_map, word_collections).stencils[:back])
            .to be nil
        end
      end
    end

    describe "#get_attribute" do
      let(:word_collections) do
        {
          front: example_front_words,
          back: example_back_words
        }
      end

      it "all attributes are obtainable using the stencil_group" do
        expect(stencil_group.get_attribute("number")).to eq "897.156.756"
        expect(stencil_group.get_attribute("parsed_number")).to eq 897156756
        expect(stencil_group.get_attribute("names")).to eq "John"
        expect(stencil_group.get_attribute("surnames")).to eq "Smith Williams"
      end
    end

    describe "#get_any?" do
      let(:word_collections) do
        {
          front: example_front_words,
          back: example_back_words
        }
      end

      it "returns the true if at least one stencil retuns true" do
        expect(stencil_group.get_any?("has_sensible_data?")).to eq true
      end
    end

    describe "#get_all?" do
      let(:word_collections) do
        {
          front: example_front_words,
          back: example_back_words
        }
      end

      it "returns the false if at least one stencil retuns false" do
        expect(stencil_group.get_all?("has_sensible_data?")).to eq false
      end
    end
  end
end
