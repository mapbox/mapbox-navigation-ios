# -*- encoding: utf-8 -*-
# stub: xcinvoke 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "xcinvoke".freeze
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Samuel E. Giddins".freeze]
  s.bindir = "exe".freeze
  s.date = "2016-11-30"
  s.email = ["segiddins@segiddins.me".freeze]
  s.homepage = "https://github.com/segiddins/xcinvoke".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Manage Xcode versions with ease!".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<liferaft>.freeze, ["~> 0.0.6"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.13"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 11.2"])
  else
    s.add_dependency(%q<liferaft>.freeze, ["~> 0.0.6"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.13"])
    s.add_dependency(%q<rake>.freeze, ["~> 11.2"])
  end
end
