# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "availability/version"

Gem::Specification.new do |s|
  s.name        = "availability"
  s.version     = Availability::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Edward Middleton"]
  s.email       = ["edward.middleton@vortorus.net"]
  s.homepage    = "https://github.com/emiddleton/availability"
  s.summary     = %q{convert local to utc offsets}
  s.description = %q{Convert weekly utc offsets to and from local times.}

  s.rubyforge_project = "availability"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
