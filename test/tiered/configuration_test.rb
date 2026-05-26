# frozen_string_literal: true

require 'test_helper'

module Tiered
  class ConfigurationTest < Minitest::Test
    def setup
      super
      @config = Configuration.new
    end

    def test_default_values
      assert_equal :free, @config.default_plan
      assert_equal :calendar_month, @config.period_cycle
      assert_equal 7, @config.grace_period_days
    end

    def test_plan_definition
      @config.plan :test_plan do |plan|
        plan.name 'Test Plan'
        plan.description 'A test plan'
        plan.price 10
      end

      plan = @config.find_plan(:test_plan)
      refute_nil plan
      assert_equal :test_plan, plan.key
      assert_equal 'Test Plan', plan.name
      assert_equal 'A test plan', plan.description
      assert_equal 10, plan.price
    end

    def test_quota_definition
      @config.plan :test do |plan|
        plan.quota :items, to: 5, per: nil, type: :persistent
        plan.quota :calls, to: 100, per: :month, type: :per_period
      end

      plan = @config.find_plan(:test)
      quota = plan.quota_for(:items)
      refute_nil quota
      assert_equal 5, quota[:to]
      assert_equal :persistent, quota[:type]
    end

    def test_restriction_definition
      @config.plan :test do |plan|
        plan.restrict :feature, values: %i[basic advanced]
      end

      plan = @config.find_plan(:test)
      restriction = plan.restriction_for(:feature)
      refute_nil restriction
      assert_equal %i[basic advanced], restriction[:values]
      assert plan.allows_feature?(:feature, :basic)
      assert plan.allows_feature?(:feature, :advanced)
      refute plan.allows_feature?(:feature, :premium)
    end
  end
end
