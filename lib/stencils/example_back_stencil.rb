class ExampleBackStencil < BaseStencil
  def self.template
    @template ||= Guillotine::Template.build do |t|
      t.set 'NAMES', at: [1.3, 0.9]
      t.set 'DOCUMENT', at: [25.4, 0.8]
      t.set 'SURNAMES', at: [1.6, 8.0]
      t.set 'ID', at: [28.9, 8.1]
    end
  end

  def self.default_max_error
    10
  end

  def face
    :back
  end

  def fields
    @fields ||= Set[
      "names",
      "surnames",
      "has_sensible_data?"
    ]
  end

  def has_sensible_data?
    false
  end

  attr_reader :names, :surnames

  def process_match
    @names = match.read([2.5, 4.4], [6.1, 6.2]).to_s
    @surnames = match.read([2.1, 13.1], [15.0, 15.0]).to_s
  end
end
