# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Services
    class QuotaEnforcerTest < Minitest::Test
      def setup
        super
        @user = create_user
      end

      def test_enforce_allows_when_within_quota
        result = QuotaEnforcer.enforce(@user, :households)

        assert_predicate result, :allowed?
        assert_nil result.message
      end

      def test_enforce_blocks_with_block_usage_policy
        create_household(user: @user)
        result = QuotaEnforcer.enforce(@user, :households)

        refute_predicate result, :allowed?
        assert_equal :block_usage, result.policy
        assert_match(/exceeded/, result.message)
      end

      def test_enforce_warns_with_just_warn_policy
        Tiered.configure do |config|
          config.plan :warn_plan do |plan|
            plan.quota :households, to: 1, per: nil, type: :persistent,
                                    scope: lambda(&:households)
            plan.after_quota_policy :just_warn
          end
        end

        @user.assign_plan!(:warn_plan)
        create_household(user: @user)
        result = QuotaEnforcer.enforce(@user, :households)

        assert_predicate result, :allowed?
        assert_equal :just_warn, result.policy
        assert_match(/exceeded|Warning/i, result.message)
      end

      def test_enforce_grace_period
        @user.assign_plan!(:plus)
        create_household(user: @user)
        create_household(user: @user, name: 'Household 2')
        create_household(user: @user, name: 'Household 3')
        # Create 4th household bypassing validation to test grace period
        household = Household.new(user: @user, name: 'Household 4')
        household.save(validate: false) # Exceeds limit of 3

        result = QuotaEnforcer.enforce(@user, :households)

        assert_predicate result, :allowed?
        assert_equal :grace_then_block, result.policy
        assert_match(/grace period/i, result.message)

        # Check quota state was created
        state = Tiered::Models::QuotaState.find_by(
          plan_owner_type: @user.class.name,
          plan_owner_id: @user.id,
          quota_key: :households
        )

        refute_nil state
        refute_nil state.exceeded_at
      end
    end
  end
end
