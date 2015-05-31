# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sexp2ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "sexp2ruby"
  spec.version       = Sexp2Ruby::VERSION
  spec.authors       = ['Ryan Davis', 'Jared Beck']
  spec.email         = ['jared@jaredbeck.com']
  spec.summary       = 'Generates ruby from RubyParser S-expressions'
  spec.description   = <<-EOS
Generates ruby from RubyParser-compatible S-expressions.
It is a fork of ruby2ruby with slightly different goals.
  EOS
  spec.homepage      = 'https://github.com/jaredbeck/sexp2ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = ">= 1.9.3"

  spec.add_runtime_dependency "sexp_processor", "~> 4.6"

  spec.add_development_dependency "rspec-core", "~> 3.2"
  spec.add_development_dependency "rspec-expectations", "~> 3.2"
  spec.add_development_dependency "rspec-mocks", "~> 3.2"
  spec.add_development_dependency "ruby_parser", "~> 3.7"
end
