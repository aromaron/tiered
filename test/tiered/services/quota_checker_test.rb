# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Services
    class QuotaCheckerTest < Minitest::Test
      def setup
        super
        @user = create_user
      end

      def test_check_persistent_quota_within_limit
        result = QuotaChecker.check(@user, :households)

        assert_predicate result, :within_quota?
        assert_equal 0, result.current
        assert_equal 1, result.limit
      end

      def test_check_persistent_quota_exceeded
        create_household(user: @user)
        result = QuotaChecker.check(@user, :households)

        refute_predicate result, :within_quota?
        assert_equal 1, result.current
        assert_equal 1, result.limit
      end

      def test_check_period_quota_within_limit
        result = QuotaChecker.check(@user, :api_calls)

        assert_predicate result, :within_quota?
        assert_equal 0, result.current
        assert_equal 100, result.limit
      end

      def test_check_period_quota_has_no_side_effects
        QuotaChecker.check(@user, :api_calls)
        usage = Tiered::Models::Usage.find_by(
          plan_owner_type: @user.class.name,
          plan_owner_id: @user.id,
          quota_key: :api_calls
        )

        assert_nil usage, 'QuotaChecker.check must not write DB rows'
      end

      def test_unlimited_quota
        # Add unlimited plan to existing config
        Tiered.configuration.plan :unlimited do |plan|
          plan.quota :items, to: :unlimited, per: nil, type: :persistent,
                             scope: lambda(&:households)
        end

        @user.assign_plan!(:unlimited)
        result = QuotaChecker.check(@user, :items)

        assert_predicate result, :unlimited?
        assert_equal Float::INFINITY, result.limit
      end

      def test_remaining_calculation
        result = QuotaChecker.check(@user, :households)

        assert_equal 1, result.remaining

        create_household(user: @user)
        result = QuotaChecker.check(@user, :households)

        assert_equal 0, result.remaining
      end

      def test_percent_used_calculation
        result = QuotaChecker.check(@user, :households)

        assert_in_delta(0.0, result.percent_used)

        create_household(user: @user)
        result = QuotaChecker.check(@user, :households)

        assert_in_delta(100.0, result.percent_used)
      end
    end
  end
end
