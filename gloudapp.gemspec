# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "gloudapp/version"

Gem::Specification.new do |s|
  s.name        = "gloudapp"
  s.version     = GloudApp::VERSION
  s.authors     = ["Christian Nicolai", "Jan Graichen"]
  s.email       = ["chrnicolai@gmail.com", "jan.graichen@altimos.de"]
  s.homepage    = ""
  s.summary     = %q{TODO: CloudApp client for GNOME/GTK}
  s.description = %q{TODO: CloudApp client for GNOME/GTK}

  s.rubyforge_project = "gloudapp"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "cloudapp_api"
  s.add_runtime_dependency "gtk2"
end
