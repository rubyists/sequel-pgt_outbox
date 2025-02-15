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
  sh "createdb '#{ENV.fetch("PGT_SPEC_DB", "postgres:///spgt_test")}'"
end

desc 'Drop the test database'
task :dropdb do
  sh "dropdb --if-exists '#{ENV.fetch("PGT_SPEC_DB", "postgres:///spgt_test")}'"
end

task resetdb: %i[dropdb createdb]

task default: %i[rubocop spec]
