require "test_helper"

describe "mina_sidekiq" do
  before do
    @old_cwd = Dir.pwd
    @env_root = TEST_ROOT.join("..", "test_env")
    Dir.chdir(@env_root)
    FileUtils.rm_rf("deploy")
  end
  after { Dir.chdir(@old_cwd) }

  def mina(task)
    cmd = "bundle exec mina --verbose #{task}"
    puts "$ #{cmd}"
    system cmd
  end

  def check_process(pid)
    pid = pid.to_i
    begin
      Process.kill(0, pid)
      return true
    rescue Errno::EPERM => e
      puts "No permission to query #{pid}!"
      raise e
    rescue Errno::ESRCH
      puts "#{pid} is NOT running."
      return false
    rescue
      puts "Unable to determine status for #{pid} : #{$!}"
    end
  end

  describe "setup" do
    before { mina "setup" }
    it "should deploy" do
      begin
        # fresh deploy
        mina "deploy"
        # second deploy
        mina "deploy"
      rescue Exception => e
        log = "./deploy/shared/sidekiq.log"
        if File.exist?(log)
          puts "cat #{log}"
          puts File.open(log).read
        end
        raise e
      end
    end
    it "should start/stop sidekiq" do
      sidekiq_pid_path = @env_root.join("deploy", "shared", "pids", "sidekiq.pid")
      # fresh deploy
      mina "deploy"
      mina "sidekiq:start"
      pid = File.read(sidekiq_pid_path)
      check_process(pid).must_equal true
      # second deploy
      mina "sidekiq:stop"
      check_process(pid).must_equal false
    end
  end
end
