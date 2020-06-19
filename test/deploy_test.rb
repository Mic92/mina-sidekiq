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

  def sidekiq_status
    `ssh localhost systemctl --user is-active sidekiq-production.service`.strip
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
      # fresh deploy
      mina "deploy"
      mina "sidekiq:start"
      _(sidekiq_status).must_equal "is_active"
      # second deploy
      mina "sidekiq:stop"
      _(sidekiq_status).wont_equal "is_active"
    end
  end
end
