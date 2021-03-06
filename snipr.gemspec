# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'snipr/version'

Gem::Specification.new do |spec|
  spec.name          = "snipr"
  spec.version       = Snipr::VERSION
  spec.authors       = ["Lance Woodson"]
  spec.email         = ["lance@webmaneuvers.com"]
  spec.summary       = %q{Take aim and fire at runaway processes using ruby}
  spec.description   = <<-END
Ruby classes and executables for targetting and sending signals to
*nix processes that match/don't match command name patterns, memory
use, cpu use and time alive
  END
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "pry"
end
