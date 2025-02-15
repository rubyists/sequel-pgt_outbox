# frozen_string_literal: true

require_relative '../pgt_outbox'

module Rubyists
  module PgtOutbox
    # The Outbox Trigger
    class Trigger
      DEFAULT_OPTS = { after: true, each_row: true }.freeze

      attr_reader(*%i[db table function events opts])

      def self.create!(db, table, function, events: %i[insert update delete], opts: { when: nil })
        new(db, table, function, events: events, opts: opts).create!
      end

      def initialize(db, table, function, events: %i[insert update delete], opts: { when: nil })
        @db = db
        @table = table
        @function = function
        @events = events
        @opts = opts
      end

      def name
        @name ||= opts.fetch(:trigger_name, function)
      end

      def create!
        db.create_trigger(table, name, function, events:, each_row:, after:, when: where)
        self
      end

      def after
        trigger_opts.fetch(:after)
      end

      def where
        opts.fetch(:when, nil)
      end

      def each_row
        trigger_opts.fetch(:each_row)
      end

      def trigger_opts
        @trigger_opts ||= DEFAULT_OPTS.merge(opts.fetch(:trigger_opts, {}))
      end
    end
  end
end
