# frozen_string_literal: true

require_relative '../pgt_outbox'
require_relative 'function'

module Rubyists
  module PgtOutbox
    # The Outbox Table
    class Table # rubocop:disable Metrics/ClassLength
      attr_reader(*%i[table opts db])

      def self.create!(table, db, opts: {})
        new(table, db, opts:).create!
      end

      def initialize(table, db, opts: {})
        @table = table
        @opts  = opts
        @db    = db
      end

      def create!
        db.run 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"' if uuid_primary_key?
        create_table!
        integer_columns!
        completed_column!
        timestamp_columns!
        string_columns!
        jsonb_columns!
        indexes!
        self
      end

      def name
        @name ||= opts.fetch(:outbox_table, "#{table}_outbox")
      end

      def timestamp_type
        opts.fetch(:timestamp_type, :timestamptz)
      end

      def quoted_name
        @quoted_name ||= db.send(:quote_schema_table, name)
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

      private

      def create_table!
        uuid_primary_key = uuid_primary_key?
        uuid_func = uuid_function
        db.create_table(name) do
          if uuid_primary_key
            uuid :id, default: Sequel.function(uuid_func), primary_key: true
          else
            primary_key :id
          end
        end
      end

      def completed_column!
        if boolean_completed_column
          db.add_column name, completed_column, FalseClass, null: false, default: false
        else
          db.add_column name, completed_column, timestamp_type
        end
        self
      end

      def integer_columns!
        db.add_column name, attempts_column, Integer, null: false, default: 0
        self
      end

      def timestamp_columns!
        db.add_column name, created_column, timestamp_type
        db.add_column name, updated_column, timestamp_type
        db.add_column name, attempted_column, timestamp_type
        self
      end

      def string_columns!
        db.add_column name, event_type_column, String, null: false
        db.add_column name, last_error_column, String
        self
      end

      def jsonb_columns!
        db.add_column name, data_before_column, :jsonb
        db.add_column name, data_after_column, :jsonb
        db.add_column name, metadata_column, :jsonb
        self
      end

      def indexes!
        db.add_index name, Sequel.asc(created_column)
        db.add_index name, Sequel.desc(attempted_column)
        self
      end
    end
  end
end
