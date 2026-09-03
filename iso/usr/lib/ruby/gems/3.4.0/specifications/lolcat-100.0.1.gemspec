# -*- encoding: utf-8 -*-
# stub: lolcat 100.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "lolcat".freeze
  s.version = "100.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Moe".freeze]
  s.date = "2025-04-18"
  s.description = "Rainbows and unicorns!".freeze
  s.email = ["moe@busyloop.net".freeze]
  s.executables = ["lolcat".freeze]
  s.files = ["bin/lolcat".freeze]
  s.homepage = "https://github.com/busyloop/lolcat".freeze
  s.rubygems_version = "3.6.7".freeze
  s.summary = "Okay, no unicorns. But rainbows!!".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<paint>.freeze, [">= 2.1".freeze])
  s.add_runtime_dependency(%q<optimist>.freeze, [">= 3.0.0".freeze])
  s.add_runtime_dependency(%q<manpages>.freeze, [">= 0.6.1".freeze])
end
