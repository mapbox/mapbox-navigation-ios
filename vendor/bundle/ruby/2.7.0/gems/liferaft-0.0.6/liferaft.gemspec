# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'liferaft/gem_version'

Gem::Specification.new do |spec|
  spec.name          = 'liferaft'
  spec.version       = Liferaft::VERSION
  spec.authors       = ['Boris Bügling']
  spec.email         = ['boris@icculus.org']
  spec.summary       = 'Liferaft parses Apple build numbers, like 6D1002'
  spec.homepage      = 'https://github.com/segiddins/liferaft'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
