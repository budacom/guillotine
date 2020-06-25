# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "guillotine/version"

Gem::Specification.new do |spec|
  spec.name          = "guillotine"
  spec.version       = Guillotine::VERSION
  spec.authors       = ["Platanus", "Antonio López"]
  spec.email         = ["rubygems@platan.us", "antoniolopezlarra@gmail.com"]
  spec.homepage      = "https://github.com/budacom/guillotine"
  spec.summary       = "Guillotine for structured documents"
  spec.description   = "A tool used to extract data from a given structured document image"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
end
