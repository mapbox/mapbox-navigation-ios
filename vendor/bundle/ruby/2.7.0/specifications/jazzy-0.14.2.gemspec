# -*- encoding: utf-8 -*-
# stub: jazzy 0.14.2 ruby lib

Gem::Specification.new do |s|
  s.name = "jazzy".freeze
  s.version = "0.14.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["JP Simard".freeze, "Tim Anglade".freeze, "Samuel Giddins".freeze, "John Fairhurst".freeze]
  s.date = "2022-03-17"
  s.description = "Soulful docs for Swift & Objective-C. Run in your SPM or Xcode project's root directory for instant HTML docs.".freeze
  s.email = ["jp@jpsim.com".freeze]
  s.executables = ["jazzy".freeze]
  s.files = ["bin/jazzy".freeze]
  s.homepage = "https://github.com/realm/jazzy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.3".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Soulful docs for Swift & Objective-C.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<cocoapods>.freeze, ["~> 1.5"])
    s.add_runtime_dependency(%q<mustache>.freeze, ["~> 1.1"])
    s.add_runtime_dependency(%q<open4>.freeze, ["~> 1.3"])
    s.add_runtime_dependency(%q<redcarpet>.freeze, ["~> 3.4"])
    s.add_runtime_dependency(%q<rexml>.freeze, ["~> 3.2"])
    s.add_runtime_dependency(%q<rouge>.freeze, [">= 2.0.6", "< 4.0"])
    s.add_runtime_dependency(%q<sassc>.freeze, ["~> 2.1"])
    s.add_runtime_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
    s.add_runtime_dependency(%q<xcinvoke>.freeze, ["~> 0.3.0"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  else
    s.add_dependency(%q<cocoapods>.freeze, ["~> 1.5"])
    s.add_dependency(%q<mustache>.freeze, ["~> 1.1"])
    s.add_dependency(%q<open4>.freeze, ["~> 1.3"])
    s.add_dependency(%q<redcarpet>.freeze, ["~> 3.4"])
    s.add_dependency(%q<rexml>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rouge>.freeze, [">= 2.0.6", "< 4.0"])
    s.add_dependency(%q<sassc>.freeze, ["~> 2.1"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1.3"])
    s.add_dependency(%q<xcinvoke>.freeze, ["~> 0.3.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
  end
end
