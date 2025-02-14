# frozen_string_literal: true

# The pgt_outbox extension adds support to the Database instance for
# implementing the transactional outbox pattern using triggers.

# Top-level Sequel namespace
module Sequel
  # Postgres namespace
  module Postgres
    Rubyists::PgtOutbox.definition = proc do # rubocop:disable Metrics/BlockLength
      def pgt_outbox_setup(table, opts = {}) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        function_name = opts.fetch(:function_name, "pgt_outbox_#{pgt_mangled_table_name(table)}")
        outbox_table  = opts.fetch(:outbox_table, "#{table}_outbox")
        quoted_outbox = quote_schema_table(outbox_table)
        event_prefix  = opts.fetch(:event_prefix, table)
        created_column = opts.fetch(:created_column, :created)
        updated_column = opts.fetch(:updated_column, :updated)
        completed_column = opts.fetch(:completed_column, :completed)
        attempts_column = opts.fetch(:attempts_column, :attempts)
        attempted_column = opts.fetch(:attempted_column, :attempted)
        event_type_column = opts.fetch(:event_type_column, :event_type)
        last_error_column = opts.fetch(:last_error_column, :last_error)
        data_after_column = opts.fetch(:data_after_column, :data_after)
        data_before_column = opts.fetch(:data_before_column, :data_before)
        metadata_column = opts.fetch(:metadata_column, :metadata)
        boolean_completed_column = opts.fetch(:boolean_completed_column, false)
        uuid_primary_key = opts.fetch(:uuid_primary_key, false)
        run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"' if uuid_primary_key
        create_table(outbox_table) do
          if uuid_primary_key
            uuid_function = opts.fetch(:uuid_function, :uuid_generate_v4)
            uuid :id, default: Sequel.function(uuid_function), primary_key: true
          else
            primary_key :id
          end
          Integer attempts_column, null: false, default: 0
          Time created_column
          Time updated_column
          Time attempted_column
          if boolean_completed_column
            FalseClass completed_column, null: false, default: false
          else
            Time completed_column
          end
          String event_type_column, null: false
          String last_error_column
          jsonb data_before_column
          jsonb data_after_column
          jsonb metadata_column
          index Sequel.asc(created_column)
          index Sequel.desc(attempted_column)
        end
        pgt_created_at outbox_table, created_column
        pgt_updated_at outbox_table, updated_column
        function_opts = { language: :plpgsql, returns: :trigger, replace: true }.merge(opts.fetch(:function_opts, {}))
        create_function(function_name, <<-SQL, function_opts)
        BEGIN
          #{pgt_pg_trigger_depth_guard_clause(opts)}
          IF (TG_OP = 'INSERT') THEN
              INSERT INTO #{quoted_outbox} ("#{event_type_column}", "#{data_after_column}") VALUES
              ('#{event_prefix}_created', to_jsonb(NEW));
              RETURN NEW;
          ELSIF (TG_OP = 'UPDATE') THEN
              INSERT INTO #{quoted_outbox} ("#{event_type_column}", "#{data_before_column}", "#{data_after_column}") VALUES
              ('#{event_prefix}_updated', to_jsonb(OLD), to_jsonb(NEW));
              RETURN NEW;
          ELSIF (TG_OP = 'DELETE') THEN
              INSERT INTO #{quoted_outbox} ("#{event_type_column}", "#{data_before_column}") VALUES
              ('#{event_prefix}_deleted', to_jsonb(OLD));
              RETURN OLD;
          END IF;
        END;
        SQL
        function_name
      end

      def pgt_outbox_events(table, function, opts = {})
        events = opts.fetch(:events, %i[insert update delete])
        where  = opts.fetch(:when, nil)
        trigger_name = opts.fetch(:trigger_name, "pgt_outbox_#{pgt_mangled_table_name(table)}")
        create_trigger(table, trigger_name, function, events:, replace: true, each_row: true, after: true, when: where)
      end

      private

      # Mangle the schema name so it can be used in an unquoted_identifier
      def pgt_mangled_table_name(table)
        quote_schema_table(table).gsub('"', '').gsub(/[^A-Za-z0-9]/, '_').gsub(/_+/, '_')
      end

      def pgt_pg_trigger_depth_guard_clause(opts)
        return unless (depth_limit = opts[:trigger_depth_limit])

        depth_limit = 1 if depth_limit == true
        depth_limit = depth_limit.to_i
        raise ArgumentError, ':trigger_depth_limit option must be at least 1' unless depth_limit >= 1

        <<-SQL
        IF pg_trigger_depth() > #{depth_limit} THEN
            RETURN NEW;
          END IF;
        SQL
      end
    end

    # The PgtOutboxMethods module provides methods for creating outbox tables and triggers
    module PgtOutBoxMethods
      class_eval(&Rubyists::PgtOutbox.definition)
    end
  end

  Database.register_extension(:pgt_outbox, Postgres::PgtOutboxMethods)
end
