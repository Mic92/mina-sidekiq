require 'mina'
require 'mina/git'
require 'mina_sidekiq/tasks'
require 'mina/git'
require 'mina/bundler'
require 'mina/rvm'
require 'fileutils'

FileUtils.mkdir_p "#{Dir.pwd}/deploy"

set :ssh_options, '-o StrictHostKeyChecking=no'

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

    # should run without error on first deployment
    invoke :'sidekiq:quiet'
    invoke :'sidekiq:stop'

    to :launch do
      invoke :'sidekiq:start'
      queue! %[sleep 3; kill -0 `cat #{sidekiq_pid}`]

      invoke :'sidekiq:quiet'

      invoke :'sidekiq:stop'
      queue! %[(kill -0 `cat #{sidekiq_pid}`) 2> /dev/null && exit 1 || exit 0]
    end
  end
end
