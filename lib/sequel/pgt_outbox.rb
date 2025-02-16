# frozen_string_literal: true

require 'sequel'
require 'sequel_postgresql_triggers'
Sequel.extension :pg_triggers
require_relative 'pgt_outbox/version'

module Rubyists
  # The main namespace for the PgtOutbox library
  module PgtOutbox
    DEFINITION = proc do
      def pgt_outbox_setup(table, opts = {})
        outbox = Rubyists::PgtOutbox.outbox_table(table, self, opts:)
        pgt_created_at outbox.name, outbox.created_column
        pgt_updated_at outbox.name, outbox.updated_column
        outbox.function.name
      end

      def pgt_outbox_events(table, function, events: %i[insert update delete], when: nil, opts: {})
        Rubyists::PgtOutbox::Trigger.create!(self, table, function, events:, opts: opts.merge(when:))
      end
    end

    def self.outbox_table(table, db, opts: {})
      require_relative 'pgt_outbox/table'
      require_relative 'pgt_outbox/trigger'
      Table.create!(table, db, opts:)
    end

    # Helper instance methods

    # Guards against recursive triggers
    # NOTE: Taken from sequel_postgresql_triggers
    # @param [Integer] depth_limit The maximum trigger depth to allow before returning NEW
    def depth_guard_clause(depth_limit = nil)
      return unless depth_limit

      depth_limit = 1 if depth_limit == true
      depth_limit = depth_limit.to_i
      raise ArgumentError, ':trigger_depth_limit option must be at least 1' unless depth_limit >= 1

      <<~SQL
        IF pg_trigger_depth() > #{depth_limit} THEN
            RETURN NEW;
        END IF;
      SQL
    end

    # Mangle the schema name so it can be used in an unquoted_identifier
    # NOTE: Taken from sequel_postgresql_triggers
    # @param [String] table The table name to mangle
    def mangled_table_name(db, table)
      db.send(:quote_schema_table, table).gsub('"', '').gsub(/[^A-Za-z0-9]/, '_').gsub(/_+/, '_')
    end
  end
end
