# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'sequel/pgt_outbox'

require 'minitest/autorun'
