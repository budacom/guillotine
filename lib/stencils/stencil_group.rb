class StencilGroup
  def self.match(_stencil_map, _document_words)
    stencils = {}
    _stencil_map.each do |face, stencil|
      return nil if !_document_words.include? face

      stencils[face] = stencil.match _document_words[face]
      return nil if stencils[face].nil?
    end

    new(stencils)
  end

  attr_reader :stencils

  def initialize(_stencils)
    @stencils = _stencils
  end

  def get_any?(_field)
    @stencils.values.each do |stencil|
      raise "Unknown field #{_field}" if !stencil.fields.include? _field
    end

    @stencils.values.any? &public_send(_field)
  end

  def get_attribute(_field)
    @stencils.values.each do |stencil|
      return stencil.public_send(_field) if stencil.fields.include? _field
    end

    raise "Unknown field #{_field}"
  end
end
