# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scash/version'

Gem::Specification.new do |spec|
  spec.name          = "scash"
  spec.version       = Scash::VERSION
  spec.authors       = ["Stephan Kaag"]
  spec.email         = ["stephan@ka.ag"]
  spec.description = spec.summary = "A scoped hash"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3"
  spec.add_development_dependency "minitest", ">= 5"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "coveralls"
end
