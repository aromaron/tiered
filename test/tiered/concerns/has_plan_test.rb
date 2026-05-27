# frozen_string_literal: true

require 'test_helper'

module Tiered
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
        assert_in_delta(0.0, @user.quota_percent_used(:households))
        Household.create!(user: @user, name: 'Household 1')

        assert_in_delta(100.0, @user.quota_percent_used(:households))
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
        assert_predicate @user, :free_plan?
        @user.assign_plan!(:plus)

        refute_predicate @user, :free_plan?
      end

      def test_paid_tier
        refute_predicate @user, :paid_plan?
        @user.assign_plan!(:plus)

        assert_predicate @user, :paid_plan?
      end

      def test_plan_allows_feature
        assert @user.plan_allows?(:split_type, :equal_parts)
        refute @user.plan_allows?(:split_type, :percentage)
      end

      # Regression: :block_usage policy must return :blocked, not :warning
      def test_quota_severity_ok_when_within_limit
        assert_equal :ok, @user.quota_severity(:households)
      end

      def test_quota_severity_blocked_for_block_usage_policy
        create_household(user: @user) # now at limit (1/1)

        assert_equal :blocked, @user.quota_severity(:households)
      end

      def test_quota_severity_warning_for_just_warn_policy
        Tiered.configure do |config|
          config.plan :warn_only do |p|
            p.name 'Warn Only'
            p.price 0
            p.quota :households, to: 1, type: :persistent, scope: lambda(&:households)
            p.after_quota_policy :just_warn
          end
        end
        @user.assign_plan!(:warn_only)
        create_household(user: @user) # now at limit (1/1)

        assert_equal :warning, @user.quota_severity(:households)
      end
    end
  end
end
