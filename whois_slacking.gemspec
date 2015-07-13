# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "whois_slacking/version"

Gem::Specification.new do |s|
  s.name        = 'whois_slacking'
  s.version     = WhoIsSlacking::VERSION 
  s.platform    = Gem::Platform::RUBY
  s.date        = '2015-07-09'
  s.summary     = "whois_slacking for whois_slacking.com"
  s.description = "Pivotal/Slack integration that sends a (daily) message of how long each user has worked on a pivotal task into a slack channel/room"
  s.authors     = ["W Watson"]
  s.email       = 'wolfpack@vulk.com'
  s.files       = ["lib/whois_slacking.rb"]
  s.homepage    = 'http://github.com/vulk/whois_slacking'
  s.license       = 'MIT'
  s.required_ruby_version = '>= 2.1.5'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec', ["~> 2.13"]
  s.add_development_dependency 'vcr',["~> 2.4"]
  s.add_development_dependency 'guard-rspec', ["~> 4.2"]
  s.add_development_dependency 'byebug'
#  s.add_development_dependency 'debugger'

  s.add_runtime_dependency "pivotal-tracker", ["~> 0.5.13"]
  # s.add_runtime_dependency "slackr", ["~> 0.0.6"]
  s.add_runtime_dependency 'slack-api', ["~> 1.1.6"]
  s.add_runtime_dependency 'time_difference', ["~> 0.4.2"]
  s.add_runtime_dependency 'moneta', ["~> 0.8.0"]
  s.add_runtime_dependency "typhoeus", ["0.3.3"]
  s.add_runtime_dependency "multi_xml", ["~> 0.5"]
  s.add_runtime_dependency "nokogiri", ["~> 1.6"]
  s.add_runtime_dependency "dotenv", ["~> 2.0.2"]

end
