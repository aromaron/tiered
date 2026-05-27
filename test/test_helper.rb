# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'bundler/setup'
require 'minitest/autorun'
require 'rails'
require 'active_record'
require 'active_support'
require 'tiered'

# Load test support
require_relative 'support/test_configuration_helper'

# Set up a test database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load migrations
ActiveRecord::Schema.define do
  create_table :tiered_assignments, force: true do |t|
    t.references :plan_owner, polymorphic: true, null: false
    t.string :plan_key, null: false
    t.string :source, null: false
    t.timestamps
  end

  add_index :tiered_assignments, %i[plan_owner_type plan_owner_id], unique: true
  add_index :tiered_assignments, :plan_key

  create_table :tiered_quota_states, force: true do |t|
    t.references :plan_owner, polymorphic: true, null: false
    t.string :quota_key, null: false
    t.datetime :exceeded_at
    t.datetime :blocked_at
    t.decimal :last_warning_threshold
    t.datetime :last_warning_at
    t.json :metadata
    t.timestamps
  end

  add_index :tiered_quota_states,
            %i[plan_owner_type plan_owner_id quota_key],
            unique: true,
            name: 'index_tiered_quota_states_unique'
  add_index :tiered_quota_states, %i[plan_owner_type plan_owner_id]

  create_table :tiered_usages, force: true do |t|
    t.references :plan_owner, polymorphic: true, null: false
    t.string :quota_key, null: false
    t.datetime :period_start, null: false
    t.datetime :period_end
    t.bigint :used, default: 0
    t.datetime :last_used_at
    t.timestamps
  end

  add_index :tiered_usages,
            %i[plan_owner_type plan_owner_id quota_key period_start],
            unique: true,
            name: 'index_tiered_usages_unique'
  add_index :tiered_usages, %i[plan_owner_type plan_owner_id]
  add_index :tiered_usages, %i[period_start period_end]

  # Test model for plan owners
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end

  # Test model for quota-limited resources
  create_table :households, force: true do |t|
    t.references :user, null: false
    t.string :name
    t.timestamps
  end
end

# Test models
class User < ActiveRecord::Base
  include Tiered::Concerns::HasPlan

  has_many :households, dependent: :destroy
end

class Household < ActiveRecord::Base
  belongs_to :user

  include Tiered::Concerns::QuotaLimited

  quota_limited_by :households,
                   plan_owner: :user,
                   error_after_quota: ->(_household) { 'Household limit exceeded' }
end

# Extend Minitest::Test with test helpers
module Minitest
  class Test
    include TestConfigurationHelper
  end
end
