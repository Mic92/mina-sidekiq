Changelog
=========

+0.4.1 2016-05-27
 +----------------
 +* Default `sidekiq_concurrency` to nil. It now needs explicitly set to
 override concurrency specified in config file

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
