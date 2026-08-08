# -*- encoding: utf-8 -*-
# stub: prop_initializer 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "prop_initializer".freeze
  s.version = "0.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/avo-hq/prop_initializer" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Paul Bob".freeze]
  s.date = "2026-05-11"
  s.description = "PropInitializer provides an easy way to define properties for Ruby classes with options for defaults and customization. It simplifies the Literal gem's functionality by removing strict type requirements and adapting the initializer process for flexibility.".freeze
  s.email = ["paul.ionut.bob@gmail.com".freeze]
  s.homepage = "https://github.com/avo-hq/prop_initializer".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.22".freeze
  s.summary = "A flexible property initializer for Ruby classes inspired by the Literal gem.".freeze

  s.installed_by_version = "4.0.17".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<zeitwerk>.freeze, [">= 2.6.18".freeze])
end
