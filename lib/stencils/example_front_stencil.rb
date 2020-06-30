class ExampleFrontStencil < BaseStencil
  def self.template
    @template ||= Guillotine::Template.build do |t|
      t.set 'DOCUMENT', at: [0.9, 0.3]
      t.set 'ID', at: [30.8, 1.2]
      t.set 'COUNTRY', at: [1.1, 8.1]
      t.set 'NUMBER', at: [0.8, 15.1]
    end
  end

  def face
    :front
  end

  def fields
    @fields ||= Set[
      "number",
      "parsed_number",
      "has_sensible_data?"
    ]
  end

  def has_sensible_data?
    true
  end

  attr_reader :number, :parsed_number

  def process_match
    @number = match.read([23.9, 15.0], [34.5, 16.9]).to_s
    @parsed_number = parse_number(@number)
  end

  private

  def parse_number(_number)
    parts = _number.split(".")
    return nil if parts.length != 3

    return nil if parts.any? { |part| !/\A\d+\z/.match(part) }

    parts.inject { |cumulate, part| cumulate + part }.to_i
  end
end
