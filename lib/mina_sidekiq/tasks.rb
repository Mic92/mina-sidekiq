# # Modules: Sidekiq
# Adds settings and tasks for managing Sidekiq workers.
#
# ## Usage example
#     require 'mina_sidekiq/tasks'
#     ...

#     task :setup do
#       # sidekiq needs a place to store its pid file
#       command %[mkdir -p "#{fetch(:deploy_to)}/shared/pids/"]
#     end
#
#     task :deploy do
#       deploy do
#         invoke :'git:clone'
#         invoke :'sidekiq:quiet'
#         invoke :'deploy:link_shared_paths'
#         ...
#
#         to :launch do
#           ...
#           invoke :'sidekiq:restart'
#         end
#       end
#     end

# ## Settings
# Any and all of these settings can be overriden in your `deploy.rb`.

# ### sidekiq
# Sets the path to sidekiq.
set :sidekiq, -> { "#{fetch(:bundle_bin)} exec sidekiq" }

# ### sidekiqctl
# Sets the path to sidekiqctl.
set :sidekiqctl, -> { "#{fetch(:bundle_bin)} exec sidekiqctl" }

# ### sidekiq_timeout
# Sets a upper limit of time a process is allowed to finish, before it is killed by sidekiqctl.
set :sidekiq_timeout, 11

# ### sidekiq_config
# Sets the path to the configuration file of sidekiq.
set :sidekiq_config, -> { "#{fetch(:shared_path)}/config/sidekiq.yml" }

# ### sidekiq_configs
# A list of configuration file paths. Each file path will be assigned to one sidekiq
# instance in order. When specified sidekiq_config will be ignored.
set :sidekiq_configs, -> {
  [
    # "#{fetch(:current_path)}/config/sidekiq_1.yml",
    # "#{fetch(:current_path)}/config/sidekiq_2.yml"
  ]
}

# ### sidekiq_log
# Sets the path to the log file of sidekiq
#
# To disable logging set it to "/dev/null"
set :sidekiq_log, -> { "#{fetch(:shared_path)}/log/sidekiq.log" }

# ### sidekiq_pid
# Sets the path to the pid file of a sidekiq worker
set :sidekiq_pid, -> { "#{fetch(:shared_path)}/pids/sidekiq.pid" }

# ### sidekiq_processes
# Sets the number of sidekiq processes launched
set :sidekiq_processes, 1

# ### sidekiq_concurrency
# Sets the number of sidekiq threads per process (overrides value in sidekiq.yml)
set :sidekiq_concurrency, nil

set :sidekiq_user, nil

# Init system integration
set :init_system, -> { nil }
# systemd integration
set :service_unit_name, "sidekiq-#{fetch(:rails_env)}.service"
set :systemctl_command, 'systemctl --user'

set :upstart_service_name, "sidekiq"

# ## Control Tasks
namespace :sidekiq do
  def for_each_process(&block)
    fetch(:sidekiq_processes).times do |idx|
      pid_file = if idx == 0
                   fetch(:sidekiq_pid)
                 else
                   "#{fetch(:sidekiq_pid)}-#{idx}"
                 end
      yield(pid_file, idx)
    end
  end

  # ### sidekiq:quiet
  desc "Quiet sidekiq (stop accepting new work)"
  task :quiet => :remote_environment do
    comment 'Quiet sidekiq (stop accepting new work)'
    case fetch(:init_system)
    when :systemd
      command %{ #{ fetch(:systemctl_command) } reload #{ fetch(:service_unit_name) } }
    when :upstart
      command %{ sudo service #{ fetch(:upstart_service_name) } reload }
    else
      in_path(fetch(:current_path)) do
        for_each_process do |pid_file, idx|
          command %{
            if [ -f #{pid_file} ] && kill -0 `cat #{pid_file}` > /dev/null 2>&1; then
              #{fetch(:sidekiqctl)} quiet #{pid_file}
            else
              echo 'Skip quiet command (no pid file found)'
            fi
          }.strip
        end
      end
    end
  end

  # ### sidekiq:stop
  desc "Stop sidekiq"
  task :stop => :remote_environment do
    comment 'Stop sidekiq'
    case fetch(:init_system)
    when :systemd
      command %{ #{ fetch(:systemctl_command) } stop #{ fetch(:service_unit_name) } }
    when :upstart
      command %{ sudo service #{ fetch(:upstart_service_name) } stop }
    else
      in_path(fetch(:current_path)) do
        for_each_process do |pid_file, idx|
          command %{
            if [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then
              #{fetch(:sidekiqctl)} stop #{pid_file} #{fetch(:sidekiq_timeout)}
            else
              echo 'Skip stopping sidekiq (no pid file found)'
            fi
          }.strip
        end
      end
    end
  end

  # ### sidekiq:start
  desc "Start sidekiq"
  task :start => :remote_environment do
    comment 'Start sidekiq'
    case fetch(:init_system)
    when :systemd
      command %{ #{ fetch(:systemctl_command) } start #{ fetch(:service_unit_name) } }
    when :upstart
      command %{ sudo service #{ fetch(:upstart_service_name) } start }
    else
      in_path(fetch(:current_path)) do
        for_each_process do |pid_file, idx|
          sidekiq_config = fetch(:sidekiq_configs)[idx] || fetch(:sidekiq_config)
          sidekiq_concurrency = fetch(:sidekiq_concurrency)
          concurrency_arg = if sidekiq_concurrency.nil?
                              ""
                            else
                              "-c #{sidekiq_concurrency}"
                            end
          command_line = %[#{fetch(:sidekiq)} -d -e #{fetch(:rails_env)} #{concurrency_arg} -C #{sidekiq_config} -i #{idx} -P #{pid_file}]
          command_line += " -L #{fetch(:sidekiq_log)}" if fetch(:sidekiq_log)

          command command_line
        end
      end
    end
  end

  task :install do
    case fetch(:init_system)
    when :systemd
      create_systemd_template
    end
  end

  task :uninstall do
    case fetch(:init_system)
    when :systemd
      command %{ #{ fetch(:systemctl_command) } disable #{fetch(:service_unit_name)} }
      command %{ rm #{File.join(fetch(:service_unit_path, fetch_systemd_unit_path), fetch(:service_unit_name))}  }
    end
  end

  def create_systemd_template
    template =  %{
[Unit]
Description=sidekiq for #{fetch(:application)} #{fetch(:app_name)}
After=syslog.target network.target

[Service]
Type=simple
Environment=RAILS_ENV=#{ fetch(:rails_env) }
StandardOutput=append:#{fetch(:sidekiq_log)}
StandardError=append:#{fetch(:sidekiq_log)}
WorkingDirectory=#{fetch(:deploy_to)}/current
ExecStart=#{fetch(:bundler_path, '/usr/local/bin/bundler')} exec sidekiq -e #{fetch(:rails_env)} -C #{fetch(:sidekiq_config)}
ExecReload=/bin/kill -TSTP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
RestartSec=1
Restart=on-failure

Environment=MALLOC_ARENA_MAX=2

SyslogIdentifier=sidekiq

[Install]
WantedBy=default.target
}
    systemd_path = fetch(:service_unit_path, fetch_systemd_unit_path)
    service_path = systemd_path + "/" + fetch(:service_unit_name)
    comment %{Creating systemctl unit file}
    command %{ mkdir -p #{systemd_path} }
    command %{ touch #{service_path} }
    command %{ echo "#{ template }" > #{ service_path } }
    comment %{Reloading systemctl daemon}
    command %{ #{ fetch(:systemctl_command) } daemon-reload }
    comment %{Enabling sidekiq service}
    command %{ #{ fetch(:systemctl_command) } enable #{ service_path } }
  end

  def fetch_systemd_unit_path
    home_dir = '/usr'
    File.join(home_dir, "lib", "systemd", "user")
  end

  # ### sidekiq:restart
  desc "Restart sidekiq"
  task :restart do
    invoke :'sidekiq:stop'
    invoke :'sidekiq:start'
  end

  desc "Tail log from server"
  task :log => :remote_environment do
    command %[tail -f #{fetch(:sidekiq_log)}]
  end

end
