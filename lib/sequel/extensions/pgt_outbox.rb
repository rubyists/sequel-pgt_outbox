# frozen_string_literal: true

require_relative '../pgt_outbox'

# The pgt_outbox extension adds support to the Database instance for
# implementing the transactional outbox pattern using triggers.
module Sequel
  # Postgres namespace
  module Postgres
    # The PgtOutboxMethods module provides methods for creating outbox tables and triggers
    module PgtOutboxMethods
      class_eval(&Rubyists::PgtOutbox::DEFINITION)
    end
  end

  Database.register_extension(:pgt_outbox, Postgres::PgtOutboxMethods)
end
