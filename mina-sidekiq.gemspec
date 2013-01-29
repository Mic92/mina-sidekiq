# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mina-sidekiq"
  s.version = File.read('VERSION')
  s.authors = ["Joerg Thalheim"]
  s.email = ["joerg@higgsboson.tk"]
  s.homepage = "http://github.com/Mic92/mina-sidekiq"
  s.summary = "Tasks to deploy Sidekiq with mina."
  s.description = "Tasks to deploy Sidekiq with mina."

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "mina"
end
