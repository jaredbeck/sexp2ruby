# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sexp2ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "sexp2ruby"
  spec.version       = Sexp2Ruby::VERSION
  spec.authors       = ['Ryan Davis', 'Jared Beck']
  spec.email         = ['jared@jaredbeck.com']
  spec.summary       = 'Generate ruby code from RubyParser S-expressions'
  spec.description   = <<-EOS
sexp2ruby generates ruby from RubyParser-compatible S-expressions.
It is a fork of [ruby2ruby][1] with slightly different goals.  It
generates ruby that follows [ruby-style-guide][3] where possible,
uses bundler instead of hoe, and uses rspec instead of minitest.
  EOS
  spec.homepage      = 'https://github.com/jaredbeck/sexp2ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = ">= 1.9.3"

  spec.add_runtime_dependency "sexp_processor"

  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "ruby_parser"
end
