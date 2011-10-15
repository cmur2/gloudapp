# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "gloudapp/info"

Gem::Specification.new do |s|
	s.name        = "gloudapp"
	s.version     = GloudApp::Info::VERSION
	s.authors     = GloudApp::Info::AUTHORS.map { |author| author[0] }
	s.email       = GloudApp::Info::AUTHORS.map { |author| author[1] }
	s.homepage    = GloudApp::Info::HOMEPAGE
	s.summary     = GloudApp::Info::SUMMARY

	s.rubyforge_project = "gloudapp"

	s.files         = `git ls-files`.split("\n")
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
	s.require_paths = ["lib"]

	s.add_runtime_dependency "cloudapp_api", '~> 0.3', '>= 0.3.2'
	s.add_runtime_dependency "gtk2", '~> 1.0'
	s.add_runtime_dependency "json"
end
