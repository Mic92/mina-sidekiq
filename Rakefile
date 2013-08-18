require 'rake'

desc 'Run integration tests'
task :test do
  Dir.chdir("#{Rake.original_dir}/test_env") do
    if ENV['FORCE_ADD_SSH_KEY']
      force_add_ssh_key
    end

    FileUtils.rm_rf('deploy')
    sh 'mina setup --verbose'
    begin
      # fresh deploy
      sh 'mina deploy --verbose'
      # second deploy
      sh 'mina deploy --verbose'
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
      log = "./deploy/shared/sidekiq.log"
      if File.exists?(log)
        puts "cat #{log}"
        puts File.open(log).read
      end
    end
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
    File.open(authorized_keys, 'a+') do |f|
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

task :default => :test
