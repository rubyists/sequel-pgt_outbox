# frozen_string_literal: true

require_relative '../pgt_outbox'

module Rubyists
  # Top-level module for the PgtOutbox gem
  module PgtOutbox
    # The Outbox Function
    class Function
      include PgtOutbox
      DEFAULT_OPTS = { language: :plpgsql, returns: :trigger, replace: true }.freeze

      attr_reader(*%i[outbox opts])

      def self.create!(outbox, opts: {})
        new(outbox, opts: opts).create!
      end

      def initialize(outbox, opts: {})
        @outbox = outbox
        @opts = opts
      end

      def name
        @name = opts.fetch(:function_name, "pgt_outbox_#{mangled_table_name(outbox.name)}")
      end

      %i[data_after_column data_before_column event_prefix event_type_column quoted_name].each do |meth|
        define_method(meth) { outbox.send(meth) }
      end

      def create! # rubocop:disable Metrics/MethodLength
        create_function(name, <<-SQL, function_opts)
        BEGIN
          #{depth_guard_clause}
          IF (TG_OP = 'INSERT') THEN
              INSERT INTO #{quoted_name} ("#{event_type_column}", "#{data_after_column}") VALUES
              ('#{event_prefix}_created', to_jsonb(NEW));
              RETURN NEW;
          ELSIF (TG_OP = 'UPDATE') THEN
              INSERT INTO #{quoted_name} ("#{event_type_column}", "#{data_before_column}", "#{data_after_column}") VALUES
              ('#{event_prefix}_updated', to_jsonb(OLD), to_jsonb(NEW));
              RETURN NEW;
          ELSIF (TG_OP = 'DELETE') THEN
              INSERT INTO #{quoted_name} ("#{event_type_column}", "#{data_before_column}") VALUES
              ('#{event_prefix}_deleted', to_jsonb(OLD));
              RETURN OLD;
          END IF;
        END;
        SQL
      end

      private

      def function_opts
        @function_opts ||= DEFAULT_OPTS.merge(opts.fetch(:function_opts, {}))
      end
    end
  end
end
