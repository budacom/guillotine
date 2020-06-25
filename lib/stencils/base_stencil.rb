class BaseStencil
  DEFAULT_MAX_ERROR = 10

  def self.match(_word_collection, max_error: DEFAULT_MAX_ERROR)
    template_match = template.match(_word_collection)

    return nil if template_match.nil?
    return nil if max_error.present? && template_match.error > max_error

    new(template_match).tap &:process_match
  end

  attr_reader :match

  def initialize(_match)
    @match = _match
  end
end
