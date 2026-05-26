# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Services
    class ConsumptionTrackerTest < Minitest::Test
      def setup
        super
        @user = create_user
      end

      def test_track_creates_usage_record
        usage = ConsumptionTracker.track(@user, :api_calls, by: 5)
        refute_nil usage
        assert_equal 5, usage.used
        assert_equal @user.class.name, usage.plan_owner_type
        assert_equal @user.id, usage.plan_owner_id
        assert_equal :api_calls, usage.quota_key.to_sym
      end

      def test_track_increments_existing_usage
        ConsumptionTracker.track(@user, :api_calls, by: 5)
        usage = ConsumptionTracker.track(@user, :api_calls, by: 3)

        assert_equal 8, usage.used
      end

      def test_track_updates_last_used_at
        usage = ConsumptionTracker.track(@user, :api_calls, by: 1)
        refute_nil usage.last_used_at
      end

      def test_reset_usage
        ConsumptionTracker.track(@user, :api_calls, by: 10)
        usage = ConsumptionTracker.reset(@user, :api_calls)

        refute_nil usage
        assert_equal 0, usage.used
        assert_nil usage.last_used_at
      end

      def test_track_only_for_per_period_quotas
        # Should return nil for persistent quotas
        result = ConsumptionTracker.track(@user, :households, by: 1)
        assert_nil result
      end

      # Regression: Usage.bump must use SQL update_all (no read-modify-write)
      def test_usage_bump_increments_via_sql
        usage = Tiered::Models::Usage.create!(
          plan_owner_type: @user.class.name,
          plan_owner_id: @user.id,
          quota_key: 'api_calls',
          period_start: Time.current.beginning_of_month,
          used: 5
        )
        Tiered::Models::Usage.bump(usage.id, 7)
        assert_equal 12, usage.reload.used
      end

      def test_track_accumulates_across_calls
        ConsumptionTracker.track(@user, :api_calls, by: 10)
        ConsumptionTracker.track(@user, :api_calls, by: 10)
        ConsumptionTracker.track(@user, :api_calls, by: 10)
        usage = Tiered::Models::Usage.find_by(
          plan_owner_type: @user.class.name,
          plan_owner_id: @user.id,
          quota_key: 'api_calls'
        )
        assert_equal 30, usage.used
      end
    end
  end
end
