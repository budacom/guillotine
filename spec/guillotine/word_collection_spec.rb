require "spec_helper"

RSpec.describe Guillotine::WordCollection do
  let(:collection) { described_class.new }

  describe "#push_word" do
    let(:box) { [[1.0, 2.0], [4.0, 2.0], [4.0, 3.0], [1.0, 3.0]] }

    it "adds a new localized word to the collection" do
      expect { collection.push_word('foo', bounding_box: box, confidence: 0.8) }
        .to change { collection.count }.by 1
      expect(collection.word(0)).to eq 'foo'
      expect(collection.location(0)).to eq [1.0, 2.0]
      expect(collection.bounding_box(0)).to eq [[1.0, 2.0], [4.0, 2.0], [4.0, 3.0], [1.0, 3.0]]
      expect(collection.confidence(0)).to eq 0.8
    end
  end

  context "when some words have been pushed" do
    before do
      collection.push_word('FOO', bounding_box: [[0.0, 3.0], [1.0, 3.0], [1.0, 4.0], [0.0, 4.0]],
                                  confidence: 1.0)
      collection.push_word('Bár', bounding_box: [[2.5, 5.0], [3.0, 4.5], [3.5, 5.0], [3.0, 5.5]],
                                  confidence: 0.5)
      collection.push_word('Qux', bounding_box: [[1.0, 3.8], [2.0, 3.8], [2.0, 4.8], [1.0, 4.8]],
                                  confidence: 0.6)
      collection.push_word('BAR', bounding_box: [[2.5, 2.9], [3.5, 2.9], [3.5, 3.9], [2.5, 3.9]],
                                  confidence: 0.8)
    end

    describe "#word" do
      it "returns the word at given index" do
        expect(collection.word(0)).to eq 'FOO'
        expect(collection.word(3)).to eq 'BAR'
      end
    end

    describe "#tl_word" do
      it "returns the tl_word at given index" do
        expect(collection.tl_word(0)).to eq 'FOO'
        expect(collection.tl_word(1)).to eq 'BAR'
      end
    end

    describe "#location" do
      it "returns the location of the word at given index" do
        expect(collection.location(0)).to eq [0.0, 3.0]
        expect(collection.location(3)).to eq [2.5, 2.9]
      end
    end

    describe "#original_location" do
      it "returns the original location of the word at given index" do
        expect(collection.original_location(0)).to eq [0.0, 3.0]
        expect(collection.original_location(3)).to eq [2.5, 2.9]
      end
    end

    describe "#bounding_box" do
      it "returns the bounding box of the word at given index" do
        expect(collection.bounding_box(0)).to eq [[0.0, 3.0], [1.0, 3.0], [1.0, 4.0], [0.0, 4.0]]
        expect(collection.bounding_box(3)).to eq [[2.5, 2.9], [3.5, 2.9], [3.5, 3.9], [2.5, 3.9]]
      end
    end

    describe "#original_bounding_box" do
      it "returns the original bounding box of the word at given index" do
        expect(collection.original_bounding_box(0))
          .to eq [[0.0, 3.0], [1.0, 3.0], [1.0, 4.0], [0.0, 4.0]]
        expect(collection.original_bounding_box(3))
          .to eq [[2.5, 2.9], [3.5, 2.9], [3.5, 3.9], [2.5, 3.9]]
      end
    end

    describe "#confidence" do
      it "returns the confidence of the word at given index" do
        expect(collection.confidence(0)).to eq 1.0
        expect(collection.confidence(2)).to eq 0.6
      end
    end

    describe "#deleted" do
      it "returns the bool 'deleted' of the word at given index" do
        expect(collection.deleted(0)).to be collection.words[0][:deleted]
        expect(collection.deleted(3)).to be collection.words[3][:deleted]
      end
    end

    describe "#search" do
      it "returns the index for words that match the given word" do
        expect(collection.search('FOO')).to contain_exactly(0)
      end

      it "compares transliterated uppercased words" do
        expect(collection.search('bar')).to contain_exactly(1, 3)
      end

      it "allows searching for words with certain level of confidence" do
        expect(collection.search('bar', min_confidence: 0.6)).to contain_exactly(3)
      end
    end

    describe "#clone" do
      it "copies the collection into a new instance" do
        expect(collection.clone.count).to eq collection.count
      end
    end

    describe "#transform" do
      it "applies a transformation matrix to the words locations but not to the originals" do
        rotation_90_deg = Matrix[[0, -1, 0], [1, 0, 0], [0, 0, 0]]

        expect { collection.transform!(rotation_90_deg) }
          .to change { collection.location(0) }.to [-3.0, 0.0]
        expect { collection.transform!(rotation_90_deg) }
          .not_to(change { collection.original_location(0) })
      end

      it "applies a transformation matrix to the bounding boxes but not to the originals" do
        rotation_90_deg = Matrix[[0, -1, 0], [1, 0, 0], [0, 0, 0]]

        expect { collection.transform!(rotation_90_deg) }
          .to change { collection.bounding_box(0) }.to [
            [-3.0, 0.0], [-3.0, 1.0], [-4.0, 1.0], [-4.0, 0.0]
          ]
        expect { collection.transform!(rotation_90_deg) }
          .not_to(change { collection.original_bounding_box(0) })
      end
    end

    describe "#read" do
      it "returns the words that have a vertex inside the given bounding box" do
        expect(collection.read([0.0, 0.0], [1.0, 3.0]).to_s).to eq 'FOO'
        expect(collection.read([3.0, 3.5], [4.0, 4.0]).to_s).to eq 'BAR'
      end

      it "returns the words that have an edge colliding with the bounding box" do
        expect(collection.read([2.5, 5.2], [4.0, 6.0]).to_s).to eq 'Bár'
        expect(collection.read([3.5, 4.5], [4.5, 5.5]).to_s).to eq 'Bár'
      end

      it "reads from top to bottom, left to right, considering the max line height" do
        expect(collection.read([0.0, 0.0], [6.0, 6.0], line_height: 0.5).to_s)
          .to eq "FOO BAR\nQux\nBár"
        expect(collection.read([0.0, 0.0], [6.0, 6.0], line_height: 1.0).to_s)
          .to eq "FOO Qux BAR\nBár"
      end

      it "returns the confidence level for the read words" do
        expect(collection.read([0.0, 0.0], [1.0, 3.0], line_height: 1.0).confidence).to eq 1.0
        expect(collection.read([0.0, 0.0], [1.1, 6.0], line_height: 0.5).confidence).to eq 0.6
      end

      it "allows filtering words by a minimum confidence" do
        expect(collection.read([0.0, 0.0], [3.0, 6.0], min_confidence: 0.9).to_s)
          .to eq 'FOO'
      end

      context "when delete is true" do
        it "returns the words found as usual" do
          expect(collection.read([0.0, 0.0], [1.0, 3.0], delete: true).to_s).to eq 'FOO'
        end

        it "marks selected words as deleted for future reads" do
          col = collection
          expect { col.read([0.0, 0.0], [1.0, 3.0], delete: true) }
            .to change { col.words[0][:deleted] }.to true
        end

        it "ignores the words marked as deleted" do
          col = collection
          col.read([0.0, 0.0], [1.0, 3.0], delete: true)
          expect(col.read([0.0, 0.0], [1.0, 3.0]).to_s).to eq ""
        end
      end
    end
  end
end
