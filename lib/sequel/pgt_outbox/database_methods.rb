# frozen_string_literal: true

require_relative '../pgt_outbox'

module Sequel
  module Postgres
    # Extends the Sequel::Database class with the PgtOutbox methods
    module DatabaseMethods
      class_eval(&Rubyists::PgtOutbox::DEFINITION)
    end
  end
end
