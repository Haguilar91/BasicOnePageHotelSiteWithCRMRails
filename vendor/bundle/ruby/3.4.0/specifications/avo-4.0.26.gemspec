# -*- encoding: utf-8 -*-
# stub: avo 4.0.26 ruby lib

Gem::Specification.new do |s|
  s.name = "avo".freeze
  s.version = "4.0.26".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/avo-hq/avo/issues", "changelog_uri" => "https://avohq.io/releases", "documentation_uri" => "https://docs.avohq.io", "homepage_uri" => "https://avohq.io", "source_code_uri" => "https://github.com/avo-hq/avo" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adrian Marin".freeze, "Mihai Marin".freeze, "Paul Bob".freeze]
  s.date = "1980-01-02"
  s.description = "Avo is a very custom Content Management System for Ruby on Rails that saves engineers and teams months of development time by building user interfaces and logic using configuration rather than traditional coding; When configuration is not enough, you can fallback to familiar Ruby on Rails code.".freeze
  s.email = ["hi@avohq.io".freeze]
  s.homepage = "https://avohq.io".freeze
  s.licenses = ["LGPL-3.0".freeze, "Commercial".freeze]
  s.post_install_message = "Thank you for using Avo \u{1F4AA}  Docs are available at https://docs.avohq.io".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "4.0.16".freeze
  s.summary = "Admin panel framework and Content Management System for Ruby on Rails.".freeze

  s.installed_by_version = "4.0.17".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, [">= 6.1".freeze])
  s.add_runtime_dependency(%q<pagy>.freeze, [">= 43.0".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, [">= 2.6.12".freeze])
  s.add_runtime_dependency(%q<active_link_to>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<view_component>.freeze, [">= 3.7.0".freeze])
  s.add_runtime_dependency(%q<turbo-rails>.freeze, [">= 2.0.0".freeze])
  s.add_runtime_dependency(%q<turbo_power>.freeze, [">= 0.6.0".freeze])
  s.add_runtime_dependency(%q<addressable>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<meta-tags>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<docile>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<prop_initializer>.freeze, [">= 0.3.0".freeze])
  s.add_runtime_dependency(%q<avo-icons>.freeze, [">= 0.1.2".freeze])
end
