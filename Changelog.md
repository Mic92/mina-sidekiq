Changelog
=========

0.4.1 2016-05-27
----------------
* defaults `sidekiq_concurrency` to nil to not override concurrency in config if not set

0.4.0 2016-05-16
----------------

* `sidekiq_concurrency`
* sidekiq_timeout is now bigger then 10s
* add task skidekiq:log

0.3.1 2015-01-18
----------------

* fix starting in background

0.2.0 2013-08-18
----------------

Breaking Changes:

* to load the tasks requiring 'mina_sidekiq/tasks' is needed now

Enhancements:

* add sidekiq_processes to allow launching multiple sidekiq instances
* improved checking, if old instances of sidekiq are still running
