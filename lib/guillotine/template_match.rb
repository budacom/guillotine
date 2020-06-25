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

    def read(_upper_left_pt, _lower_right_pt, _line_height, _exclusion, delete: false)
      @words.read _upper_left_pt, _lower_right_pt, _line_height, _exclusion, delete
    end

    def read_relative(_label, _upper_left_pt, _lower_right_pt, _line_height, _exclusion,
      delete: false)
      ref_pt = @labels[_label]
      raise ArgumentError, 'invalid label' if ref_pt.nil?

      @words.read(
        [ref_pt[0] + _upper_left_pt[0], ref_pt[1] + _upper_left_pt[1]],
        [ref_pt[0] + _lower_right_pt[0], ref_pt[1] + _lower_right_pt[1]],
        _line_height, _exclusion, delete
      )
    end
  end
end
