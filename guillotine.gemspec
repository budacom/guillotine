require 'rake'

Gem::Specification.new do |s|
  s.name        = 'guillotine'
  s.version     = '0.0.0'
  s.date        = '2020-06-24'
  s.summary     = "Guillotine for structured documents"
  s.description = "A tool used to extract data from a given structured document image"
  s.authors     = ["Antonio López"]
  s.email       = 'antoniolopezlarra@gmail.com'
  s.files       = FileList["lib/guillotine.rb", "lib/guillotine/*.rb"].to_a
  s.homepage    = 'https://github.com/budacom/guillotine'
  s.license     = 'MIT'

  # s.add_dependency 'example', '~> 1.1', '>= 1.1.4'
end
