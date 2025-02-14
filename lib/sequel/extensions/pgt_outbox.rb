# frozen_string_literal: true

require_relative '../pgt_outbox'

# The pgt_outbox extension adds support to the Database instance for
# implementing the transactional outbox pattern using triggers.
module Sequel
  # Postgres namespace
  module Postgres
    Rubyists::PgtOutbox.definition = proc do
      def pgt_outbox_setup(table, opts = {})
        outbox = Rubyists::PgtOutbox.create_table!(table, self, opts:)
        pgt_created_at outbox.name, outbox.created_column
        pgt_updated_at outbox.name, outbox.updated_column
        outbox.function.name
      end

      def pgt_outbox_events(table, function, events: %i[insert update delete], where: nil, opts: {})
        Rubyists::PgtOutbox::OutboxTrigger.create!(table, function, events:, where:, opts:)
      end
    end

    # The PgtOutboxMethods module provides methods for creating outbox tables and triggers
    module PgtOutboxMethods
      class_eval(&Rubyists::PgtOutbox.definition)
    end
  end

  Database.register_extension(:pgt_outbox, Postgres::PgtOutboxMethods)
end
