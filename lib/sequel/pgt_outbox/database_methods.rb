# frozen_string_literal: true

require 'sequel/extensions/pgt_outbox'

module Sequel
  module Postgres
    # Extends the Sequel::Database class with the PgtOutbox methods
    module DatabaseMethods
      class_eval(&Rubyists::PgtOutbox::PGT_DEFINE)
    end
  end
end
