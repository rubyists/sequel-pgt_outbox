# frozen_string_literal: true

require_relative '../extensions/pgt_outbox'

module Sequel
  module Postgres
    # Extends the Sequel::Database class with the PgtOutbox methods
    module DatabaseMethods
      class_eval(&Rubyists::PgtOutbox.definition)
    end
  end
end
