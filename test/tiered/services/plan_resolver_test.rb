# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Services
    class PlanResolverTest < Minitest::Test
      def setup
        super
        @user = create_user
      end

      def test_resolves_default_plan_when_no_assignment
        plan = PlanResolver.resolve(@user)
        refute_nil plan
        assert_equal :free, plan.key
      end

      def test_resolves_assigned_plan
        PlanResolver.assign_plan!(@user, :plus, source: 'manual')
        plan = PlanResolver.resolve(@user)
        assert_equal :plus, plan.key
      end

      def test_assign_plan_creates_assignment
        assignment = PlanResolver.assign_plan!(@user, :plus, source: 'manual')
        refute_nil assignment
        assert_equal :plus, assignment.plan_key.to_sym
        assert_equal 'manual', assignment.source
        assert_equal @user.class.name, assignment.plan_owner_type
        assert_equal @user.id, assignment.plan_owner_id
      end

      def test_assign_plan_raises_error_for_invalid_plan
        assert_raises(PlanNotFoundError) do
          PlanResolver.assign_plan!(@user, :invalid_plan)
        end
      end

      def test_remove_plan
        PlanResolver.assign_plan!(@user, :plus)
        refute_nil PlanResolver.resolve(@user)

        PlanResolver.remove_plan!(@user)
        plan = PlanResolver.resolve(@user)
        assert_equal :free, plan.key
      end
    end
  end
end
