# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'process_lock/version'

Gem::Specification.new do |spec|
  spec.name          = "process_lock"
  spec.version       = ProcessLock::VERSION
  spec.authors       = ["Simon Engledew", "Ian Heggie"]
  spec.email         = ["ian@heggie.biz"]
  spec.description   = %q{A simple class to aquire and check process-id file based locks on a unix filesystem.}
  spec.summary       = %q{Use process lock to see if a process is already running or designate a master process when running concurrent applications.}
  spec.homepage      = "https://github.com/ianheggie/ruby-process-lock"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", '~> 2.0'
end
