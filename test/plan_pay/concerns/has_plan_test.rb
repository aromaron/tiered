# frozen_string_literal: true

require 'test_helper'

module PlanPay
  module Concerns
    class HasPlanTest < Minitest::Test
      def setup
        super
        @user = create_user
      end

      def test_current_plan_returns_default
        assert_equal :free, @user.current_plan.key
      end

      def test_plan_key
        assert_equal :free, @user.plan_key
      end

      def test_within_quota
        assert @user.within_quota?(:households)
        Household.create!(user: @user, name: 'Household 1')
        refute @user.within_quota?(:households)
      end

      def test_quota_remaining
        assert_equal 1, @user.quota_remaining(:households)
        Household.create!(user: @user, name: 'Household 1')
        assert_equal 0, @user.quota_remaining(:households)
      end

      def test_quota_percent_used
        assert_equal 0.0, @user.quota_percent_used(:households)
        Household.create!(user: @user, name: 'Household 1')
        assert_equal 100.0, @user.quota_percent_used(:households)
      end

      def test_plan_quota_for
        assert_equal 1, @user.plan_quota_for(:households)
        assert_equal 100, @user.plan_quota_for(:api_calls)
      end

      def test_assign_plan
        @user.assign_plan!(:plus)
        assert_equal :plus, @user.plan_key
      end

      def test_free_tier
        assert @user.free_tier?
        @user.assign_plan!(:plus)
        refute @user.free_tier?
      end

      def test_paid_tier
        refute @user.paid_tier?
        @user.assign_plan!(:plus)
        assert @user.paid_tier?
      end

      def test_plan_allows_feature
        assert @user.plan_allows?(:split_type, :equal_parts)
        refute @user.plan_allows?(:split_type, :percentage)
      end
    end
  end
end
