# frozen_string_literal: true

require_relative '../pgt_outbox'

module Rubyists
  module PgtOutbox
    # A PostgreSQL trigger that sends a NOTIFY on a channel when rows are inserted into the outbox
    class NotifyTrigger
      include PgtOutbox

      DEFAULT_OPTS = { language: :plpgsql, returns: :trigger, replace: true }.freeze
      TRIGGER_DEFAULT_OPTS = { after: true, each_statement: true, replace: true }.freeze

      attr_reader(*%i[outbox db channel function_name trigger_name opts])

      def self.create!(outbox, channel:, function_name: nil, trigger_name: nil, opts: {})
        new(outbox, channel:, function_name:, trigger_name:, opts:).create!
      end

      def initialize(outbox, channel:, function_name: nil, trigger_name: nil, opts: {})
        @outbox = outbox
        @db = outbox.db
        @channel = channel
        @function_name = function_name || "pgt_outbox_notify_#{mangled_table_name(db, outbox.name)}"
        @trigger_name = trigger_name || "pgt_outbox_notify_after_insert_#{mangled_table_name(db, outbox.name)}"
        @opts = opts
      end

      def create!
        create_function!
        create_trigger!
        self
      end

      private

      def create_function!
        db.create_function(function_name, function_sql, function_opts)
      end

      def function_sql
        <<~SQL
          BEGIN
            PERFORM pg_catalog.pg_notify('#{channel}', '');
            RETURN NULL;
          END;
        SQL
      end

      def function_opts
        @function_opts ||= DEFAULT_OPTS.merge(opts.fetch(:function_opts, {}))
      end

      def create_trigger!
        db.create_trigger(
          outbox.name,
          trigger_name,
          function_name,
          after: true,
          each_statement: true,
          events: [:insert],
          replace: true
        )
      end
    end
  end
end
