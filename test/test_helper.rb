require "minitest/autorun"
require 'pathname'

TEST_ROOT = Pathname.new(File.dirname(__FILE__))

module MiniTestWithHooks
  class Unit < MiniTest::Unit
    def before_suites; end
    def after_suites; end

    def _run_suites(suites, type)
      begin
        before_suites
        super(suites, type)
      ensure
        after_suites
      end
    end

    def _run_suite(suite, type)
      begin
        suite.before_suite
        super(suite, type)
      ensure
        suite.after_suite
      end
    end
  end
end

module MiniTestWithTransactions
  class Unit < MiniTestWithHooks::Unit
    def before_suites
      super
      if ENV["FORCE_ADD_SSH_KEY"]
        force_add_ssh_key
      end
    end
    def force_add_ssh_key(&block)
      ssh_key = File.expand_path("~/.ssh/id_rsa.pub")
      unless File.exists?(ssh_key)
        sh "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
      end
      file = File.open(ssh_key)
      pub_key = file.readline
      file.close

      authorized_keys = File.expand_path("~/.ssh/authorized_keys")
      begin
        File.open(authorized_keys, "a+") do |f|
          File.chmod(0600, authorized_keys)
          f.puts(pub_key)
        end
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
      ensure
        File.chmod(0400, authorized_keys)
      end
    end
  end
end
