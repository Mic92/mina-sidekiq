# -*- encoding: utf-8 -*-

require "./lib/mina_sidekiq/version.rb"

Gem::Specification.new do |s|
  s.name = "mina-sidekiq"
  s.version = MinaSidekiq.version
  s.authors = ["Joerg Thalheim"]
  s.email = ["joerg@higgsboson.tk"]
  s.homepage = "http://github.com/Mic92/mina-sidekiq"
  s.summary = "Tasks to deploy Sidekiq with mina."
  s.description = "Adds tasks to aid in the deployment of Sidekiq"
  s.license = "MIT"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'mina'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'minitest'
end
