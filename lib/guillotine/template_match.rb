module Guillotine
  class TemplateMatch
    attr_reader :labels, :words, :error, :transform

    def initialize(_labels, _words, _error, _transform)
      @labels = _labels
      @error = _error
      @words = _words
      @transform = _transform
    end

    def [](_key)
      @labels[_key]
    end

    def read(_upper_left_pt, _lower_right_pt, line_height: 2.0, exclusion: Set[], delete: false)
      @words.read(_upper_left_pt,
        _lower_right_pt,
        line_height: line_height,
        exclusion: exclusion,
        delete: delete)
    end

    def read_relative(_label, _upper_left_pt, _lower_right_pt, line_height: 2.0, exclusion: Set[],
      delete: false)
      ref_pt = @labels[_label]
      raise ArgumentError, 'invalid label' if ref_pt.nil?

      @words.read(
        [ref_pt[0] + _upper_left_pt[0], ref_pt[1] + _upper_left_pt[1]],
        [ref_pt[0] + _lower_right_pt[0], ref_pt[1] + _lower_right_pt[1]],
        line_height: line_height, exclusion: exclusion, delete: delete
      )
    end
  end
end
