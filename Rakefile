# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Run tests'
task :spec do
  ENV['COVERAGE'] = 'true'
  sh 'bundle exec ./test/sequel/test_pgt_outbox.rb'
end

desc 'Create the test database'
task :createdb do
  require 'uri'
  uri = URI.parse(ENV.fetch('PGT_SPEC_DB', 'postgres:///spgt_test'))
  sh "createdb '#{File.basename(uri.path)}'"
end

desc 'Drop the test database'
task :dropdb do
  require 'uri'
  uri = URI.parse(ENV.fetch('PGT_SPEC_DB', 'postgres:///spgt_test'))
  sh "dropdb --if-exists '#{File.basename(uri.path)}'"
end

task resetdb: %i[dropdb createdb]

task default: %i[rubocop spec]
