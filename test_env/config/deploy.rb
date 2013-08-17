require 'mina'
require 'mina/git'
require 'mina-sidekiq'
require 'mina/git'
require 'mina/bundler'
require 'mina/rvm'
require 'fileutils'

FileUtils.mkdir_p "#{Dir.pwd}/deploy"

set :domain, 'localhost'
set :deploy_to, "#{Dir.pwd}/deploy"
set :repository, 'https://github.com/Mic92/mina-sidekiq-test-rails.git'
set :keep_releases, 2

task :environment do
  invoke :'rvm:use[ruby-2.0.0]'
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
end

task :deploy => :environment do
  deploy do
    invoke :'git:clone'
    invoke :'bundle:install'
    invoke :'sidekiq:start'

    # stop accepting new workers
    #invoke :'sidekiq:quiet'

    invoke :'sidekiq:stop'
  end
end
