require 'matrix'
require 'active_support'

module Guillotine
  class WordCollection
    class ReadString
      attr_reader :string, :confidence

      def initialize(_string, _confidence)
        @string = _string
        @confidence = _confidence
      end

      def to_s
        @string
      end
    end

    def self.build_from_url(_url, _google_vision_api_key)
      word_layout = VisionUtils.get_word_layout(_url, _google_vision_api_key)
      new.tap do |collection|
        word_layout.each do |wtext, bounding_box, confidence|
          collection.push_word(wtext, bounding_box: bounding_box, confidence: confidence)
        end
      end
    end

    attr_reader :words

    def initialize(words = [])
      @words = words
    end

    def word(_index)
      @words[_index][:word]
    end

    def tl_word(_index)
      @words[_index][:tl_word]
    end

    def location(_index)
      @words[_index][:bounding_box][0]
    end

    def confidence(_index)
      @words[_index][:conf]
    end

    def original_location(_index)
      @words[_index][:original_bounding_box][0]
    end

    def bounding_box(_index)
      @words[_index][:bounding_box]
    end

    def original_bounding_box(_index)
      @words[_index][:original_bounding_box]
    end

    def deleted(_index)
      @words[_index][:deleted]
    end

    def count
      @words.count
    end

    def push_word(_word, bounding_box:, confidence: 1.0)
      @words << {
        word: _word,
        tl_word: I18n.transliterate(_word).upcase,
        conf: confidence,
        bounding_box: bounding_box,
        original_bounding_box: bounding_box.clone,
        deleted: false
      }
    end

    def search(_word, min_confidence: 0.0)
      word = I18n.transliterate(_word).upcase
      @words.each_index.select do |i|
        @words[i][:tl_word] == word && @words[i][:conf] >= min_confidence
      end
    end

    def clone
      self.class.new.tap do |coll_clone|
        @words.each do |w|
          coll_clone.push_word_raw(w)
        end
      end
    end

    def transform!(_matrix)
      @words.each do |w|
        w[:original_bounding_box].each_with_index do |vertex, index|
          new_vertex = (_matrix * Matrix.column_vector(vertex + [1.0])).transpose.to_a.first[0..1]
          w[:bounding_box][index] = new_vertex
        end
      end

      self
    end

    def read(_upper_left_pt, _lower_right_pt, line_height: 2.0, exclusion: Set[], delete: false,
      min_confidence: 0)
      read_words = select_inside_box(
        _upper_left_pt,
        _lower_right_pt,
        min_confidence,
        exclusion,
        delete
      )
      confidence = read_words.map { |w| w[:conf] }.min || 1.0

      lines = []
      while !read_words.empty?
        line_words, read_words = partition_by_line(read_words, line_height)

        lines << line_words.sort_by { |w| w[:bounding_box][0][0] }.map { |w| w[:word] }.join(' ')
      end

      ReadString.new lines.join("\n"), confidence
    end

    protected

    def push_word_raw(_raw)
      @words << _raw
    end

    def select_inside_box(_upper_left_pt, _lower_right_pt, _min_confidence, _exclusion, _delete)
      inside_box = []
      @words.each do |w|
        next if _exclusion.include? w[:tl_word]

        aabb = { "min": _upper_left_pt, "max": _lower_right_pt }
        if w[:conf] >= _min_confidence &&
            BoundingBoxUtils.collides?(aabb, w[:bounding_box]) && !w[:deleted]
          inside_box << w
          w[:deleted] = true if _delete
        end
      end
      inside_box
    end

    def partition_by_line(_words, _line_height)
      upper_word = _words.min { |a, b| a[:bounding_box][0][1] <=> b[:bounding_box][0][1] }

      _words.partition do |word|
        word[:bounding_box][0][1] - upper_word[:bounding_box][0][1] < _line_height
      end
    end
  end
end
