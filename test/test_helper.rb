# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'sequel'

if (coverage = ENV.delete('COVERAGE'))
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    command_name coverage
    add_filter '/spec/'
    add_group('Missing') { |src| src.covered_percent < 100 }
    add_group('Covered') { |src| src.covered_percent == 100 }
  end
end

ENV['MT_NO_PLUGINS'] = '1' # Work around stupid autoloading of plugins
gem 'minitest'
require 'minitest/global_expectations/autorun'

DB = Sequel.connect(ENV['PGT_SPEC_DB'] || 'postgres:///spgt_test')

if ENV['PGT_GLOBAL'] == '1'
  puts 'Running specs with global modification'
  require 'sequel/pgt_outbox'
else
  puts 'Running specs with extension'
  DB.extension :pgt_outbox
end
DB.extension :pg_json
