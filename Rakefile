begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = '-fd'
  end
rescue LoadError
end

task :default => :spec
