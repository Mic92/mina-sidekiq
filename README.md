mina-sidekiq
============

mina-sidekiq is a gem that adds tasks to aid in the deployment of [Sidekiq](http://mperham.github.com/sidekiq/)
using [Mina](http://nadarei.co/mina).

Starting with 1.0.0 this gem requires Mina 1.0! (thanks [@devvmh](https://github.com/devvmh))

Support sidekiq > 6.0, reference project capistrano-sidekiq, github: https://github.com/seuros/capistrano-sidekiq

# Getting Start

## Installation

```console
gem install mina-sidekiq
```

## Example

```ruby
require 'mina_sidekiq/tasks'
#...

task :setup do
  # sidekiq needs a place to store its pid file and log file
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/pids/")
  command %(mkdir -p "#{fetch(:deploy_to)}/shared/log/")
end

task :deploy do
  deploy do
    # stop accepting new workers
    invoke :'git:clone'
    invoke :'sidekiq:quiet'
    invoke :'deploy:link_shared_paths'
    ...

    on :launch do
      ...
      invoke :'sidekiq:restart'
    end
  end
end
```
## Support sidekiq > 6.0

Set init system to systemd in the mina deploy config:

```ruby
  set :init_system, :systemd
```

Enable lingering for systemd user account

```
  loginctl enable-linger USERACCOUNT
```

Install systemd.service template file and enable the service with:

```
  bundle exec mina sidekiq:install
```

Default name for the service file is sidekiq-env.service. This can be changed as needed, for example:

```ruby
  set :service_unit_name, "sidekiq-#{fetch(:rails_env)}.service"
```

Default systemctl command is ```systemctl --user```, this can be changed, for example:

```ruby
  set :systemctl_command, 'systemctl --user'
```
For non privileged user (non sudo) usage set up path for systemctl unit file:

```ruby
  set :service_unit_path, '/home/www/.config/systemd/user'
```

where ```www``` is the username. For details see systemctl [doc page](https://www.freedesktop.org/software/systemd/man/systemd.unit.html) 

To use systemctl integration with rbenv bundler path must be setted:

```ruby
  set :bundler_path, '/home/www/.rbenv/shims/bundler'
```

To get bundler path use:

```bash
  which bundler
```


## Integration with upstart

Set init system to upstart in the cap deploy config:

```ruby
  set :init_system, :upstart
```

Set upstart service name:

```ruby
  set :upstart_service_name, 'sidekiq'
```


## Available Tasks

* sidekiq:stop
* sidekiq:start
* sidekiq:restart
* sidekiq:quiet
* sidekiq:log

sidekiq > 6.0
* sidekiq:install
* sidekiq:uninstall

## Available Options

| Option              | Description                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------- |
| *sidekiq*           | Sets the path to sidekiq.                                                                         |
| *sidekiqctl*        | Sets the path to sidekiqctl.                                                                      |
| *sidekiq\_timeout*  | Sets a upper limit of time a worker is allowed to finish, before it is killed.                    |
| *sidekiq\_log*      | Sets the path to the log file of sidekiq.                                                         |
| *sidekiq\_pid*      | Sets the path to the pid file of a sidekiq worker.                                                |
| *sidekiq_processes* | Sets the number of sidekiq processes launched.                                                    |
| *sidekiq_config*    | Sets the config file path.                                                                        |
| *sidekiq_configs*   | Sets the config file paths when using more than one sidekiq process with different configuration. |

## Testing

The test requires a local running ssh server with the ssh keys of the current
user added to its `~/.ssh/authorized_keys`. In OS X, this is "Remote Login"
under the Sharing pref pane. You will also need a working rvm installation.

To run the full blown test suite use:

```console
bundle exec rake test
```

For faster release cycle use

```console
cd test_env
bundle exec mina deploy --verbose
```

## Copyright

Copyright (c) 2016 Jörg Thalheim <joerg@higgsboson.tk>

See LICENSE for further details.
