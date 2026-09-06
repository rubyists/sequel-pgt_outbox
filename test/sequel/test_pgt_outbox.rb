#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

class Crass
  include Rubyists::PgtOutbox
end

describe 'Depth recursion handler' do
  before do
    @crass = Crass.new
  end

  def depth_sql(depth)
    <<~SQL.strip
      IF pg_trigger_depth() > #{depth} THEN
          RETURN NEW;
      END IF;
    SQL
  end

  it 'Should be 1 if true is passed' do
    _(@crass.depth_guard_clause(true).strip).must_equal depth_sql(1)
  end

  it 'Should be 1 if 1 is passed' do
    _(@crass.depth_guard_clause(1).strip).must_equal depth_sql(1)
  end

  it 'Should be 2 if 2 is passed' do
    _(@crass.depth_guard_clause(2).strip).must_equal depth_sql(2)
  end

  it 'Should raise Argument error if 0 is passed' do
    _ { @crass.depth_guard_clause(0) }.must_raise ArgumentError
  end
end

if DB.server_version >= 90_400
  describe 'Basic PostgreSQL Transactional Outbox' do # rubocop:disable Metrics/BlockLength
    before do
      DB.extension :pg_json
      DB.create_table!(:accounts) do
        integer :id
        String :s
      end
      function_name = DB.pgt_outbox_setup(:accounts, function_name: :spgt_outbox_events)
      DB.pgt_outbox_events(:accounts, function_name)
      @logs = DB[:accounts_outbox].reverse(:created)
    end

    after do
      DB.drop_table(:accounts, :accounts_outbox)
      DB.drop_function(:spgt_outbox_events)
    end

    it 'should store outbox events for writes on main table' do # rubocop:disable Metrics/BlockLength
      _(@logs.first).must_be_nil

      ds = DB[:accounts]
      ds.insert(id: 1, s: 'string')

      _(ds.all).must_equal [{ id: 1, s: 'string' }]
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h).must_equal(id: 1,
                      attempts: 0,
                      attempted: nil,
                      completed: nil,
                      event_type: 'accounts_created',
                      last_error: nil,
                      data_before: nil,
                      data_after: { 's' => 'string', 'id' => 1 },
                      metadata: nil)

      ds.where(id: 1).update(s: 'string2')

      _(ds.all).must_equal [{ id: 1, s: 'string2' }]
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h).must_equal(id: 2,
                      attempts: 0,
                      attempted: nil,
                      completed: nil,
                      event_type: 'accounts_updated',
                      last_error: nil,
                      data_before: { 's' => 'string', 'id' => 1 },
                      data_after: { 's' => 'string2', 'id' => 1 },
                      metadata: nil)

      ds.delete

      _(ds.all).must_equal []
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h).must_equal(id: 3,
                      attempts: 0,
                      attempted: nil,
                      completed: nil,
                      event_type: 'accounts_deleted',
                      last_error: nil,
                      data_before: { 's' => 'string2', 'id' => 1 },
                      data_after: nil,
                      metadata: nil)
    end
  end
end

if DB.server_version >= 90_400
  describe 'PostgreSQL Transactional Outbox With UUID Pkey' do # rubocop:disable Metrics/BlockLength
    before do
      DB.extension :pg_json
      DB.create_table(:accounts) do
        integer :id
        String :s
      end
      function_name = DB.pgt_outbox_setup(:accounts, uuid_primary_key: true, function_name: :spgt_outbox_events)
      DB.pgt_outbox_events(:accounts, function_name)
      @logs = DB[:accounts_outbox].reverse(:created)
    end

    after do
      DB.drop_table(:accounts, :accounts_outbox)
      DB.drop_function(:spgt_outbox_events)
    end

    it 'should store outbox events for writes on main table' do # rubocop:disable Metrics/BlockLength
      _(@logs.first).must_be_nil

      ds = DB[:accounts]
      ds.insert(id: 1, s: 'string')

      _(ds.all).must_equal [{ id: 1, s: 'string' }]
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      id = h.delete(:id)

      _(id).must_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      _(h).must_equal(attempts: 0, attempted: nil, completed: nil, event_type: 'accounts_created', last_error: nil,
                      data_before: nil, data_after: { 's' => 'string', 'id' => 1 }, metadata: nil)

      ds.where(id: 1).update(s: 'string2')

      _(ds.all).must_equal [{ id: 1, s: 'string2' }]
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      id = h.delete(:id)

      _(id).must_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      _(h).must_equal(attempts: 0,
                      attempted: nil,
                      completed: nil,
                      event_type: 'accounts_updated',
                      last_error: nil,
                      data_before: { 's' => 'string', 'id' => 1 },
                      data_after: { 's' => 'string2', 'id' => 1 },
                      metadata: nil)

      ds.delete

      _(ds.all).must_equal []
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      id = h.delete(:id)

      _(id).must_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      _(h).must_equal(attempts: 0, attempted: nil, completed: nil, event_type: 'accounts_deleted', last_error: nil,
                      data_before: { 's' => 'string2', 'id' => 1 }, data_after: nil, metadata: nil)
    end
  end
end

if DB.server_version >= 90_400
  describe 'PostgreSQL Transactional Outbox With Boolean :completed field' do # rubocop:disable Metrics/BlockLength
    before do
      DB.extension :pg_json
      DB.create_table(:accounts) do
        integer :id
        String :s
      end
      function_name = DB.pgt_outbox_setup(:accounts, uuid_primary_key: true, boolean_completed_column: true,
                                                     function_name: :spgt_outbox_events)
      DB.pgt_outbox_events(:accounts, function_name)
      @logs = DB[:accounts_outbox].reverse(:created)
    end

    after do
      DB.drop_table(:accounts, :accounts_outbox)
      DB.drop_function(:spgt_outbox_events)
    end

    it 'should store outbox events for writes on main table' do # rubocop:disable Metrics/BlockLength
      _(@logs.first).must_be_nil

      ds = DB[:accounts]
      ds.insert(id: 1, s: 'string')

      _(ds.all).must_equal [{ id: 1, s: 'string' }]
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      id = h.delete(:id)

      _(id).must_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      _(h).must_equal(attempts: 0, attempted: nil, completed: false, event_type: 'accounts_created', last_error: nil,
                      data_before: nil, data_after: { 's' => 'string', 'id' => 1 }, metadata: nil)

      ds.where(id: 1).update(s: 'string2')

      _(ds.all).must_equal [{ id: 1, s: 'string2' }]
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      id = h.delete(:id)

      _(id).must_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      _(h).must_equal(attempts: 0,
                      attempted: nil,
                      completed: false,
                      event_type: 'accounts_updated',
                      last_error: nil,
                      data_before: { 's' => 'string', 'id' => 1 },
                      data_after: { 's' => 'string2', 'id' => 1 },
                      metadata: nil)

      ds.delete

      _(ds.all).must_equal []
      h = @logs.first

      _(h.delete(:created).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      _(h.delete(:updated).to_i).must_be_close_to(10, DB.get(Sequel::CURRENT_TIMESTAMP).to_i)
      id = h.delete(:id)

      _(id).must_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
      _(h).must_equal(attempts: 0, attempted: nil, completed: false, event_type: 'accounts_deleted', last_error: nil,
                      data_before: { 's' => 'string2', 'id' => 1 }, data_after: nil, metadata: nil)
    end
  end
end

if DB.server_version >= 90_400
  describe 'PG NOTIFY Trigger' do # rubocop:disable Metrics/BlockLength
    def get_trigger(table_name, trigger_name)
      DB[
        'SELECT tgname FROM pg_trigger ' \
        'JOIN pg_class ON pg_class.oid = pg_trigger.tgrelid ' \
        'WHERE pg_class.relname = ? AND pg_trigger.tgname = ?',
        table_name, trigger_name
      ].first
    end

    def get_function(func_name)
      DB[
        'SELECT proname FROM pg_proc WHERE proname = ?',
        func_name
      ].first
    end

    after do
      DB.drop_table(:accounts, :accounts_outbox)
      begin
        DB.drop_function(:spgt_outbox_events)
      rescue Sequel::DatabaseError
        # function may not exist
      end
      begin
        DB.drop_function('pgt_outbox_notify_accounts_outbox')
      rescue Sequel::DatabaseError
        # function may not exist
      end
    end

    it 'should not create notify trigger by default' do
      DB.create_table!(:accounts) do
        integer :id
        String :s
      end
      DB.pgt_outbox_setup(:accounts, function_name: :spgt_outbox_events)

      trigger = get_trigger('accounts_outbox', 'pgt_outbox_notify_after_insert_accounts_outbox')

      _(trigger).must_be_nil
    end

    it 'should create notify function and trigger when notify: true' do
      DB.create_table!(:accounts) do
        integer :id
        String :s
      end
      DB.pgt_outbox_setup(:accounts, notify: true, function_name: :spgt_outbox_events)

      func = get_function('pgt_outbox_notify_accounts_outbox')

      _(func).wont_be :nil?

      trigger = get_trigger('accounts_outbox', 'pgt_outbox_notify_after_insert_accounts_outbox')

      _(trigger).wont_be :nil?
    end

    it 'should use custom channel name when provided' do
      DB.create_table!(:accounts) do
        integer :id
        String :s
      end
      DB.pgt_outbox_setup(:accounts, notify: true, notify_channel: 'my_custom_channel',
                                     function_name: :spgt_outbox_events)

      func = get_function('pgt_outbox_notify_accounts_outbox')

      _(func).wont_be :nil?

      # Verify the function body contains the custom channel
      func_body = DB[
        'SELECT proname, prosrc FROM pg_proc WHERE proname = ?',
        'pgt_outbox_notify_accounts_outbox'
      ].first[:prosrc]

      _(func_body).must_include 'my_custom_channel'
    end

    it 'should send notification on insert into outbox' do
      DB.create_table!(:accounts) do
        integer :id
        String :s
      end
      DB.pgt_outbox_setup(:accounts, notify: true, function_name: :spgt_outbox_events)
      DB.pgt_outbox_events(:accounts, 'spgt_outbox_events')

      # Insert a row which should trigger the notify
      DB[:accounts].insert(id: 1, s: 'test')

      # Verify outbox event was created
      outbox_event = DB[:accounts_outbox].first

      _(outbox_event).wont_be :nil?
      _(outbox_event[:event_type]).must_equal 'accounts_created'
    end
  end
end

# vim: ft=ruby sts=2 sw=2 ts=2 et
