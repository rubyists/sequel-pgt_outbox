# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Run tests'
task :spec do
  ENV['COVERAGE'] = 'true'
  sh 'bundle exec ./test/sequel/test_pgt_outbox.rb'
end

task default: %i[rubocop spec]
