# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Concerns
    class QuotaLimitedTest < Minitest::Test
      def setup
        super
        @user = create_user
      end

      def test_validation_passes_when_within_quota
        household = Household.new(user: @user, name: 'Household 1')
        assert household.valid?
      end

      def test_validation_fails_when_quota_exceeded
        Household.create!(user: @user, name: 'Household 1')
        household = Household.new(user: @user, name: 'Household 2')
        refute household.valid?
        assert_includes household.errors.full_messages.join(' '), 'limit exceeded'
      end

      def test_plan_owner_for_quota
        household = Household.new(user: @user, name: 'Household 1')
        assert_equal @user, household.plan_owner_for_quota
      end

      def test_quota_key_for_resource
        household = Household.new(user: @user, name: 'Household 1')
        assert_equal :households, household.quota_key_for_resource
      end
    end
  end
end
