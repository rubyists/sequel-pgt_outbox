# frozen_string_literal: true

require_relative '../pgt_outbox'
require_relative 'function'

module Rubyists
  module PgtOutbox
    # The Outbox Table
    class Table
      attr_reader(*%i[table opts db])

      def self.create!(table, db, opts: {})
        new(table, db, opts:).create!
      end

      def initialize(table, db, opts: {})
        @table = table
        @opts  = opts
        @db    = db
      end

      def create! # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        db.run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"' if uuid_primary_key?
        db.create_table(outbox_table) do
          if uuid_primary_key
            uuid :id, default: Sequel.function(uuid_function), primary_key: true
          else
            primary_key :id
          end
          Integer attempts_column, null: false, default: 0
          column created_column, timestamp_type
          column updated_column, timestamp_type
          column attempted_column, timestamp_type
          if boolean_completed_column
            FalseClass completed_column, null: false, default: false
          else
            column completed_column, timestamp_type
          end
          String event_type_column, null: false
          String last_error_column
          jsonb data_before_column
          jsonb data_after_column
          jsonb metadata_column
          index Sequel.asc(created_column)
          index Sequel.desc(attempted_column)
        end
      end

      def name
        @name ||= opts.fetch(:outbox_table, "#{table}_outbox")
      end

      def timestamp_type
        opts.fetch(:timestamp_type, :timestamptz)
      end

      def quoted_name
        @quoted_name ||= Sequel.quote_schema_table(name)
      end

      def event_prefix
        @event_prefix ||= opts.fetch(:event_prefix, table)
      end

      def created_column
        @created_column ||= opts.fetch(:created_column, :created)
      end

      def updated_column
        @updated_column ||= opts.fetch(:updated_column, :updated)
      end

      def completed_column
        @completed_column ||= opts.fetch(:completed_column, :completed)
      end

      def attempts_column
        @attempts_column ||= opts.fetch(:attempts_column, :attempts)
      end

      def attempted_column
        @attempted_column ||= opts.fetch(:attempted_column, :attempted)
      end

      def event_type_column
        @event_type_column ||= opts.fetch(:event_type_column, :event_type)
      end

      def last_error_column
        @last_error_column ||= opts.fetch(:last_error_column, :last_error)
      end

      def data_after_column
        @data_after_column ||= opts.fetch(:data_after_column, :data_after)
      end

      def data_before_column
        @data_before_column ||= opts.fetch(:data_before_column, :data_before)
      end

      def metadata_column
        @metadata_column ||= opts.fetch(:metadata_column, :metadata)
      end

      def boolean_completed_column
        @boolean_completed_column ||= opts.fetch(:boolean_completed_column, false)
      end

      def uuid_primary_key?
        @uuid_primary_key ||= opts.fetch(:uuid_primary_key, false)
      end

      def uuid_function
        @uuid_function ||= opts.fetch(:uuid_function, :uuid_generate_v4)
      end

      def function
        @function ||= Function.create!(self, opts:)
      end
    end
  end
end
