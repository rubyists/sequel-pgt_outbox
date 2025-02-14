# frozen_string_literal: true

require_relative '../pgt_outbox'

module Rubyists
  module PgtOutbox
    # The Outbox Trigger
    class OutboxTrigger
      DEFAULT_OPTS = { after: true }.freeze

      def self.create!(table, function, events: %i[insert update delete], where: nil, opts: {})
        new(table, function, events: events, where: where, opts: opts).create!
      end

      def initialize(table, function, events: %i[insert update delete], where: nil, opts: {})
        @table = table
        @function = function
        @events = events
        @where = where
        @opts = opts
      end

      def create!
        create_trigger(name, <<-SQL, trigger_opts)
        BEGIN
        SQL
      end

      def trigger_opts
        @trigger_opts ||= DEFAULT_OPTS.merge(opts.fetch(:trigger_opts, {}))
      end
    end
  end
end
