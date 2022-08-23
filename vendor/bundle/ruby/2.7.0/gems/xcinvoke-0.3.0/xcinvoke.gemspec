# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xcinvoke/version'

Gem::Specification.new do |spec|
  spec.name          = 'xcinvoke'
  spec.version       = XCInvoke::VERSION
  spec.authors       = ['Samuel E. Giddins']
  spec.email         = ['segiddins@segiddins.me']

  spec.summary       = 'Manage Xcode versions with ease!'
  spec.homepage      = 'https://github.com/segiddins/xcinvoke'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_runtime_dependency 'liferaft', '~> 0.0.6'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 11.2'
end
