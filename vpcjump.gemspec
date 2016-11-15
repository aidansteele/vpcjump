# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vpcjump/version'

Gem::Specification.new do |spec|
  spec.name          = 'vpcjump'
  spec.version       = Vpcjump::VERSION
  spec.authors       = ['Aidan Steele']
  spec.email         = ['aidan.steele@glassechidna.com.au']
  spec.homepage      = 'https://github.com/aidansteele/vpcjump'

  spec.summary       = %q{Helper tool for connecting to jumpboxes in AWS.}

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'

  spec.add_dependency 'clamp'
  spec.add_dependency 'aws-sdk', '~> 2'
end
