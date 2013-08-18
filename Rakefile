desc 'Run integration tests'
task :test do
  Dir.chdir("#{Rake.original_dir}/test_env") do
    sh 'mina deploy'
  end
end
task :default => :test
