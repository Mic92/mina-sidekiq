# # Modules: Sidekiq
# Adds settings and tasks for managing Sidekiq workers.
#
# ## Usage example
#     require 'mina_sidekiq/tasks'
#     ...
#     task :setup do
#       # sidekiq needs a place to store its pid file
#       queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
#     end
#
#     task :deploy do
#       deploy do
#         invoke :'sidekiq:quiet'
#         invoke :'git:clone'
#         ...
#
#         to :launch do
#           ...
#           invoke :'sidekiq:restart'
#         end
#       end
#     end

require 'mina/bundler'
require 'mina/rails'

# ## Settings
# Any and all of these settings can be overriden in your `deploy.rb`.

# ### sidekiq
# Sets the path to sidekiq.
set_default :sidekiq, lambda { "#{bundle_bin} exec sidekiq" }

# ### sidekiqctl
# Sets the path to sidekiqctl.
set_default :sidekiqctl, lambda { "#{bundle_prefix} sidekiqctl" }

# ### sidekiq_timeout
# Sets a upper limit of time a process is allowed to finish, before it is killed by sidekiqctl.
set_default :sidekiq_timeout, 11

# ### sidekiq_config
# Sets the path to the configuration file of sidekiq
set_default :sidekiq_config, lambda { "#{deploy_to}/#{current_path}/config/sidekiq.yml" }

# ### sidekiq_log
# Sets the path to the log file of sidekiq
#
# To disable logging set it to "/dev/null"
set_default :sidekiq_log, lambda { "#{deploy_to}/#{current_path}/log/sidekiq.log" }

# ### sidekiq_pid
# Sets the path to the pid file of a sidekiq worker
set_default :sidekiq_pid, lambda { "#{deploy_to}/#{shared_path}/pids/sidekiq.pid" }

# ### sidekiq_processes
# Sets the number of sidekiq processes launched
set_default :sidekiq_processes, 1

# ### sidekiq_concurrency
# Sets the number of sidekiq threads per process (overrides value in sidekiq.yml)
set_default :sidekiq_concurrency, nil

# ## Control Tasks
namespace :sidekiq do
  def for_each_process(&block)
    sidekiq_processes.times do |idx|
      pid_file = if idx == 0
                   sidekiq_pid
                 else
                   "#{sidekiq_pid}-#{idx}"
                 end
      yield(pid_file, idx)
    end
  end

  # ### sidekiq:quiet
  desc "Quiet sidekiq (stop accepting new work)"
  task :quiet => :environment do
    queue %[echo "-----> Quiet sidekiq (stop accepting new work)"]
    for_each_process do |pid_file, idx|
      queue %{
        if [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then
          cd "#{deploy_to}/#{current_path}"
          #{echo_cmd %{#{sidekiqctl} quiet #{pid_file}} }
        else
          echo 'Skip quiet command (no pid file found)'
        fi
      }
    end
  end

  # ### sidekiq:stop
  desc "Stop sidekiq"
  task :stop => :environment do
    queue %[echo "-----> Stop sidekiq"]
    for_each_process do |pid_file, idx|
      queue %[
        if [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then
          cd "#{deploy_to}/#{current_path}"
          #{echo_cmd %[#{sidekiqctl} stop #{pid_file} #{sidekiq_timeout}]}
        else
          echo 'Skip stopping sidekiq (no pid file found)'
        fi
      ]
    end
  end

  # ### sidekiq:start
  desc "Start sidekiq"
  task :start => :environment do
    queue %[echo "-----> Start sidekiq"]
    for_each_process do |pid_file, idx|
      concurrency_arg = if sidekiq_concurrency.nil?
                          ""
                        else
                          "-c #{sidekiq_concurrency}"
                        end
      queue %{
        cd "#{deploy_to}/#{current_path}"
        #{echo_cmd %[#{sidekiq} -d -e #{rails_env} #{concurrency_arg} -C #{sidekiq_config} -i #{idx} -P #{pid_file} -L #{sidekiq_log}] }
      }
    end
  end

  # ### sidekiq:restart
  desc "Restart sidekiq"
  task :restart do
    invoke :'sidekiq:stop'
    invoke :'sidekiq:start'
  end

  desc "Tail log from server"
  task :log => :environment do
    queue %[tail -f #{sidekiq_log}]
  end

end
