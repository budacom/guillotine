class BaseStencil
  def self.match(_word_collection, max_error: default_max_error)
    template_match = template.match(_word_collection)

    return nil if template_match.nil?
    return nil if max_error.present? && template_match.error > max_error

    new(template_match).tap &:process_match
  end

  def self.default_max_error
    nil
  end

  attr_reader :match

  def initialize(_match)
    @match = _match
  end
end
