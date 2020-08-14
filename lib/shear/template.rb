require 'active_support'
require 'active_support/core_ext'

module Shear
  class Template
    def self.build(&_block)
      template = new
      _block.call(template)
      template.seal
      template
    end

    attr_reader :sealed, :fixtures, :exclusions

    def initialize
      @sealed = false
      @fixtures = []
      @exclusions = {}
    end

    def set(_word, at: nil, label: nil, filter: nil)
      raise 'template sealed' if @sealed

      @fixtures << [_word, at, label, filter]
    end

    def set_exclusion(_field_name, _excluded_word)
      raise 'template sealed' if @sealed

      @exclusions[_field_name] = Set[] if !@exclusions.include?(_field_name)
      @exclusions[_field_name] << I18n.transliterate(_excluded_word).upcase
    end

    def get_exclusions(_field_name)
      @exclusions.include?(_field_name) ? @exclusions[_field_name] : Set[]
    end

    def seal
      @sealed = true
    end

    def match(_word_collection)
      filtered_words_collection = filter_words(_word_collection)
      return nil if should_discard_stencil?(filtered_words_collection.words)

      recursive_match(filtered_words_collection, [], 0)
    end

    private

    def should_discard_stencil?(_words)
      return true if should_discard_stencil_by_discard_fixture?(_words)
      return true if should_discard_stencil_by_unique_fixture?(_words)

      false
    end

    def should_discard_stencil_by_discard_fixture?(_words)
      discard_fixtures_tl =
        @fixtures
        .select { |f| f[3] == 'discard' }
        .map { |f| I18n.transliterate(f[0]).upcase }
      return true if _words.any? { |w| discard_fixtures_tl.include? w[:tl_word] }

      false
    end

    def should_discard_stencil_by_unique_fixture?(_words)
      unique_fixtures_tl =
        @fixtures.select { |f| f[3] == 'unique' }.map { |f| I18n.transliterate(f[0]).upcase }
      unique_fixture_words =
        _words.map { |w| w[:tl_word] }.select { |tl_w| unique_fixtures_tl.include? tl_w }
      return true if unique_fixture_words.uniq.length != unique_fixture_words.length

      false
    end

    def filter_words(_word_collection)
      filtered_words = reject_words_with_duplicate_bounding_box(_word_collection.words)
      filtered_words = select_big_words_with_larger_bounding_box(filtered_words)
      filtered_words = select_words_with_high_confidence(filtered_words)
      WordCollection.new(filtered_words)
    end

    def reject_words_with_duplicate_bounding_box(_words)
      _words.uniq { |w| [w[:original_bounding_box], w[:tl_word]] }
    end

    def select_big_words_with_larger_bounding_box(_words)
      big_fixtures_tl =
        @fixtures.select { |f| f[3] == 'big' }.map { |f| I18n.transliterate(f[0]).upcase }
      big_fixture_words = _words.select { |w| big_fixtures_tl.include? w[:tl_word] }
      non_big_fixture_words = _words - big_fixture_words
      filtered_big_words =
        big_fixture_words
        .sort_by { |w| distance(w[:original_bounding_box][0], w[:original_bounding_box][1]) }
        .reverse
        .uniq { |w| w[:tl_word] }
      non_big_fixture_words + filtered_big_words
    end

    def select_words_with_high_confidence(_words)
      confidence_fixtures_tl =
        @fixtures.select { |f| f[3] == 'confidence' }.map { |f| I18n.transliterate(f[0]).upcase }
      confidence_fixture_words = _words.select { |w| confidence_fixtures_tl.include? w[:tl_word] }
      non_confidence_fixture_words = _words - confidence_fixture_words
      filtered_confidence_words =
        confidence_fixture_words
        .sort_by { |w| w[:conf] }
        .reverse
        .uniq { |w| w[:tl_word] }
      non_confidence_fixture_words + filtered_confidence_words
    end

    def recursive_match(_words, _result, _fixture_index) # rubocop:disable all
      word_indexes = []
      while word_indexes.empty?
        return calculate_match(_words, _result) if _fixture_index == @fixtures.length

        word, _, _, word_filter = @fixtures[_fixture_index]
        word_indexes = _words.search(word)
        _fixture_index += 1 if word_indexes.empty? || word_filter == 'discard'
      end
      return calculate_match(_words, _result) if _fixture_index == @fixtures.length

      word_indexes.inject(nil) do |best_match, word_index|
        new_result = _result + [[word_index, _fixture_index]]
        match = recursive_match(_words, new_result, _fixture_index + 1)
        next match if best_match.nil?
        next best_match if match.nil?

        match.error < best_match.error ? match : best_match
      end
    end

    def calculate_match(_words, _result) # rubocop:disable AbcSize, MethodLength
      # select 3 points and calculate transformation matrix (solve T for W * T = F)

      return nil if _result.length <= 3

      word_loc1 = _words.original_location(_result.first[0]) + [1]
      word_loc2 = _words.original_location(_result.second[0]) + [1]
      word_loc3 = _words.original_location(_result.third[0]) + [1]

      matrix_w = Matrix[word_loc1, word_loc2, word_loc3]
      matrix_f = Matrix[
        @fixtures[_result.first[1]][1] + [1],
        @fixtures[_result.second[1]][1] + [1],
        @fixtures[_result.third[1]][1] + [1]
      ]

      raise "Found locations are collinear" if matrix_w.singular?

      transform = (matrix_w.inverse * matrix_f).transpose

      # transform collection

      norm_words = _words.clone.transform! transform

      # calculate error mean(distance_from_fixture ^ 2)

      errors = _result[3..-1].each.map do |index_pair|
        distance(norm_words.location(index_pair[0]), @fixtures[index_pair[1]][1])
      end

      TemplateMatch.new(
        load_labeled_points(_result, norm_words), norm_words, mean_sq_error(errors), transform
      )
    end

    def load_labeled_points(_result, _words)
      Hash[_result.each.map do |index_pair|
        fixture_label = @fixtures[index_pair[1]][2]
        word_location = _words.location(index_pair[0])
        [fixture_label, word_location] if fixture_label
      end.reject(&:nil?)]
    end

    def distance(_pt1, _pt2)
      Math.sqrt((_pt2[0].to_d - _pt1[0])**2 + (_pt2[1].to_d - _pt1[1])**2)
    end

    def mean_sq_error(_errors)
      _errors.sum { |e| e * e } / _errors.count
    end
  end
end
