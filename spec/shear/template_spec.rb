require "spec_helper"

RSpec.describe Shear::Template do
  context "when the stencils has not been sealed" do
    let(:template) { described_class.new }

    describe "#set" do
      it "registers a new pinned word in the template" do
        expect { template.set 'REPÚBLICA', at: [21.6, 8.0] }.not_to raise_error
      end

      it "stores a fixture on the template" do
        expect { template.set 'REPÚBLICA', at: [21.6, 8.0] }.to change { template.fixtures }
          .to [['REPÚBLICA', [21.6, 8.0], nil, nil]]
      end
    end

    describe "#set_exclusion" do
      it "registers a new exclusion for a given field" do
        expect { template.set_exclusion :surnames, 'APELLIDOS' }.not_to raise_error
      end

      it "stores a exclusion on the template" do
        expect { template.set_exclusion :surnames, 'APELLIDOS' }
          .to change { template.get_exclusions(:surnames) }.to Set['APELLIDOS']
      end

      it "stores the transliterated word on the template" do
        expect { template.set_exclusion :surnames, 'República' }
          .to change { template.get_exclusions(:surnames) }.to Set['REPUBLICA']
      end
    end

    describe "#seal" do
      it "seals the template, preventing it from being modified" do
        expect { template.seal }.to change { template.sealed }.to true
      end
    end
  end

  context "when given a sealed template with registered words" do
    let(:front_template) do
      described_class.build do |t|
        t.set 'DOCUMENT', at: [0.9, 0.3]
        t.set 'ID', at: [30.8, 1.2]
        t.set 'COUNTRY', at: [1.1, 8.1]
        t.set 'NUMBER', at: [0.8, 15.1]
        t.set_exclusion :number, 'extra'
        t.set_exclusion :number, 'text'
      end
    end

    let(:back_template) do
      described_class.build do |t|
        t.set 'NAMES', at: [1.3, 0.9], label: :names
        t.set 'DOCUMENT', at: [25.4, 0.8]
        t.set 'SURNAMES', at: [1.6, 8.0], label: :surnames
        t.set 'ID', at: [28.9, 8.1]
        t.set_exclusion :surnames, 'Smith'
      end
    end

    let(:back_words) do
      Shear::WordCollection.new.tap do |w|
        w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
        w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]])
        w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
        w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
        w.push_word('ID', bounding_box: [[178, 421], [178, 439], [145, 439], [145, 421]])
        w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
        w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
      end
    end

    let(:front_words) do
      Shear::WordCollection.new.tap do |w|
        w.push_word('Document', bounding_box: [[210, 27], [401, 114], [385, 150], [193, 63]])
        w.push_word('country', bounding_box: [[169, 122], [248, 159], [234, 189], [155, 152]])
        w.push_word('number', bounding_box: [[120, 211], [205, 246], [194, 272], [109, 237]])
        w.push_word('number', bounding_box: [[120, 211], [205, 246], [194, 272], [109, 237]])
        w.push_word('ID', bounding_box: [[588, 208], [603, 214], [594, 236], [579, 230]])
        w.push_word('897.156.756', bounding_box: [[414, 338], [551, 397], [539, 425], [402, 366]])
      end
    end

    let(:blury_front_words) do
      Shear::WordCollection.new.tap do |w|
        w.push_word('country', bounding_box: [[169, 122], [248, 159], [234, 189], [155, 152]])
        w.push_word('number', bounding_box: [[120, 211], [205, 246], [194, 272], [109, 237]])
        w.push_word('ID', bounding_box: [[588, 208], [603, 214], [594, 236], [579, 230]])
        w.push_word('897.156.756', bounding_box: [[414, 338], [551, 397], [539, 425], [402, 366]])
      end
    end

    describe "#get_exclusions" do
      it "allows to get exclusions for a given field" do
        expect(front_template.get_exclusions(:number)).to eq(Set['EXTRA', 'TEXT'])
      end
    end

    describe "#set" do
      it "fails because template is sealed" do
        expect { front_template.set 'CEDULA', at: [21.6, 8.0] }.to raise_error(RuntimeError)
      end
    end

    describe "#match" do
      let(:front_match) { front_template.match(front_words) }
      let(:back_match) { back_template.match(back_words) }
      let(:surname_back_exclusions) { back_template.get_exclusions(:surnames) }

      it "properly calculates the match error" do
        expect(front_match.error).to be < 5
        expect(back_match.error).to be < 5
      end

      it "properly transforms the word collection" do
        expect(front_match.read([23.9, 15.0], [34.5, 16.9]).to_s).to eq "897.156.756"
      end

      it "properly ignores excluded words from the respective fields" do
        expect(back_match.read([2.1, 13.1], [15.0, 15.0]).to_s).to eq "Smith Williams"
        expect(back_match.read([2.1, 13.1], [15.0, 15.0], exclusion: surname_back_exclusions).to_s)
          .to eq "Williams"
      end

      it "marks words as deleted when using 'delete'" do
        expect { back_match.read([2.1, 13.1], [15.0, 15.0], delete: true) }
          .to change { back_match.words.deleted(5) }.to true
      end

      it "properly ignores deleted words when reading" do
        expect(back_match.read([2.1, 13.1], [15.0, 15.0], delete: true).to_s)
          .to eq "Smith Williams"
        expect(back_match.read([2.1, 13.1], [15.0, 15.0]).to_s).to eq ""
      end

      it "allows accessing labeled points" do
        expect(back_match[:names]).to be_instance_of(Array)
        expect(back_match[:surnames]).to be_instance_of(Array)
      end

      it "allows reading words relative to a label using match.read_relative" do
        expect(back_match.read_relative(:names, [1, 3], [5, 6]).to_s).to eq "John"
      end

      it "marks words as deleted when using 'delete' on read_relative" do
        expect { back_match.read_relative(:names, [1, 3], [5, 6], delete: true) }
          .to change { back_match.words.deleted(2) }.to true
      end

      it "properly ignores deleted words when reading realative" do
        expect(back_match.read_relative(:names, [1, 3], [5, 6], delete: true).to_s)
          .to eq "John"
        expect(back_match.read_relative(:names, [1, 3], [5, 6], delete: true).to_s)
          .to eq ""
      end

      it "filters duplicate words with same bounding box" do
        expect(front_match.words.words.select { |word| word[:tl_word] == "NUMBER" }.count).to eq 1
      end
    end
  end

  context "when using filters on the template" do
    let(:template) do
      described_class.build do |t|
        t.set 'NAMES', at: [1.3, 0.9]
        t.set 'DOCUMENT', at: [25.4, 0.8], filter: 'confidence'
        t.set 'SURNAMES', at: [1.6, 8.0], filter: 'unique'
        t.set 'ID', at: [28.9, 8.1], filter: 'big'
        t.set 'NUMBER', filter: 'discard'
      end
    end

    let(:words) do
      Shear::WordCollection.new.tap do |w|
        w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
        w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]],
                                confidence: 1.0)
        w.push_word('document', bounding_box: [[204, 277], [193, 401], [160, 399], [271, 374]],
                                confidence: 0.8)
        w.push_word('document', bounding_box: [[104, 177], [93, 301], [60, 299], [71, 174]],
                                confidence: 0.5)
        w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
        w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
        w.push_word('ID', bounding_box: [[178, 421], [178, 439], [145, 439], [145, 421]])
        w.push_word('ID', bounding_box: [[158, 401], [158, 414], [120, 414], [120, 401]])
        w.push_word('ID', bounding_box: [[138, 381], [138, 394], [100, 394], [100, 381]])
        w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
        w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
      end
    end

    let(:match) { template.match words }

    it "filters all smalles copies of a word with keyword 'big'" do
      expect(match.words.words.select { |word| word[:tl_word] == "ID" }.count).to eq 1
      expect(match.words.words.select { |word| word[:tl_word] == "ID" }[0][:original_bounding_box])
        .to eq [[178, 421], [178, 439], [145, 439], [145, 421]]
    end

    it "filters all low confidence copies of a word with keywords 'confidence'" do
      expect(match.words.words.select { |word| word[:tl_word] == "DOCUMENT" }.count).to eq 1
      expect(match.words.words.select do |word|
        word[:tl_word] == "DOCUMENT"
      end[0][:original_bounding_box]).to eq [[304, 377], [293, 501], [260, 499], [271, 374]]
    end

    context "when 'unique' word is twice on the image" do
      let(:words) do
        Shear::WordCollection.new.tap do |w|
          w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
          w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]])
          w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
          w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
          w.push_word('surnames', bounding_box: [[309, 133], [299, 254], [266, 251], [276, 130]])
          w.push_word('ID', bounding_box: [[178, 421], [178, 439], [145, 439], [145, 421]])
          w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
          w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
        end
      end

      it "match returns nil" do
        expect(template.match words).to eq nil
      end
    end

    context "when 'discard' word is on the image" do
      let(:words) do
        Shear::WordCollection.new.tap do |w|
          w.push_word('Document', bounding_box: [[210, 27], [401, 114], [385, 150], [193, 63]])
          w.push_word('country', bounding_box: [[169, 122], [248, 159], [234, 189], [155, 152]])
          w.push_word('number', bounding_box: [[120, 211], [205, 246], [194, 272], [109, 237]])
          w.push_word('ID', bounding_box: [[588, 208], [603, 214], [594, 236], [579, 230]])
          w.push_word('897.156.756', bounding_box: [[414, 338], [551, 397], [539, 425], [402, 366]])
        end
      end

      it "match returns nil" do
        expect(template.match words).to eq nil
      end
    end
  end

  context "when fixture words have more than one option on the word collection" do
    let(:back_template) do
      described_class.build do |t|
        t.set 'NAMES', at: [1.3, 0.9]
        t.set 'DOCUMENT', at: [25.4, 0.8]
        t.set 'SURNAMES', at: [1.6, 8.0]
        t.set 'ID', at: [28.9, 8.1]
      end
    end

    let(:back_words) do
      Shear::WordCollection.new.tap do |w|
        w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
        w.push_word('document', bounding_box: [[512, 120], [500, 200], [480, 200], [490, 120]])
        w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]])
        w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
        w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
        w.push_word('ID', bounding_box: [[421, 178], [439, 178], [439, 145], [421, 145]])
        w.push_word('ID', bounding_box: [[178, 421], [178, 439], [145, 439], [145, 421]])
        w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
        w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
      end
    end

    describe "#match" do
      it "chooses a low error convination" do
        expect(back_template.match(back_words).error).to be < 5
      end
    end
  end

  context "when not all fixtures are present in word collection" do
    let(:template) do
      described_class.build do |t|
        t.set 'NAMES', at: [1.3, 0.9]
        t.set 'DOCUMENT', at: [25.4, 0.8]
        t.set 'NUMBER', at: [12.5, 6.4]
        t.set 'SURNAMES', at: [1.6, 8.0]
        t.set 'ID', at: [28.9, 8.1]
      end
    end

    context "when there are 4 or more fixtures present" do
      let(:words) do
        Shear::WordCollection.new.tap do |w|
          w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
          w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]])
          w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
          w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
          w.push_word('ID', bounding_box: [[178, 421], [178, 439], [145, 439], [145, 421]])
          w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
          w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
        end
      end

      it "finds a match" do
        expect(template.match words).not_to be nil
      end
    end

    context "when there are less than 4 fixtures present" do
      let(:words) do
        Shear::WordCollection.new.tap do |w|
          w.push_word('names', bounding_box: [[323, 27], [318, 112], [294, 110], [299, 26]])
          w.push_word('document', bounding_box: [[304, 377], [293, 501], [260, 499], [271, 374]])
          w.push_word('John', bounding_box: [[270, 43], [267, 93], [234, 91], [237, 41]])
          w.push_word('surnames', bounding_box: [[209, 33], [199, 154], [166, 151], [176, 30]])
          w.push_word('Smith', bounding_box: [[126, 37], [120, 102], [86, 99], [92, 34]])
          w.push_word('Williams', bounding_box: [[120, 112], [111, 219], [77, 216], [86, 109]])
        end
      end

      it "if returns nil" do
        expect(template.match words).to be nil
      end
    end
  end
end
