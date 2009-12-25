require 'rubygems'
require 'rake'

begin

  gem 'jeweler', '>= 1.4'
  require 'jeweler'

  require File.expand_path('../lib/dm-reflection/version', __FILE__)

  FileList['tasks/**/*.rake'].each { |task| load task }

  Jeweler::Tasks.new do |gem|

    gem.version     = DataMapper::Reflection::VERSION

    gem.name        = "dm-reflection"
    gem.summary     = %Q{Generates datamapper models from existing database schemas}
    gem.description = %Q{Generates datamapper models from existing database schemas and export them to files}
    gem.email       = "gamsnjaga@gmail.com"
    gem.homepage    = "http://github.com/snusnu/dm-schema_reflection"
    gem.authors     = ["Martin Gamsjaeger (snusnu)"]

    gem.add_dependency 'dm-core', '~> 0.10.2'

    gem.add_development_dependency 'rspec', '~> 1.2.9'
    gem.add_development_dependency 'yard',  '~> 0.5'

  end

  Jeweler::GemcutterTasks.new

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :spec => :check_dependencies
task :default => :spec
