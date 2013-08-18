mina-sidekiq
============

[![Build Status](https://travis-ci.org/Mic92/mina-sidekiq.png?branch=master)](https://travis-ci.org/Mic92/mina-sidekiq)

mina-sidekiq is a gem that adds tasks to aid in the deployment of [Sidekiq] (http://mperham.github.com/sidekiq/)
using [Mina] (http://nadarei.co/mina).

# Getting Start

## Installation

    gem install mina-sidekiq

## Example

## Usage example

    require 'mina_sidekiq/tasks'
    ...
    task :setup do
      # sidekiq needs a place to store its pid file
      queue! %[mkdir -p "#{deploy_to}/shared/pids/"]
    end

    task :deploy do
      deploy do
        # stop accepting new workers
        invoke :'sidekiq:quiet'
        invoke :'git:clone'
        ...

        to :launch do
          ...
          invoke :'sidekiq:restart'
        end
      end
    end

## Available Tasks

* sidekiq:stop
* sidekiq:start
* sidekiq:restart
* sidekiq:quiet

## Available Options

* sidekiq: Sets the path to sidekiq.
* sidekiqctl: Sets the path to sidekiqctl.
* sidekiq\_timeout: Sets a upper limit of time a worker is allowed to finish, before it is killed.
* sidekiq\_log: Sets the path to the log file of sidekiq
* sidekiq\_pid: Sets the path to the pid file of a sidekiq worker

## Copyright

Copyright (c) 2013 Jörg Thalheim http://higgsboson.tk/joerg

See LICENSE for further details.
