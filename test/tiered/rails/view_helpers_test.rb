# frozen_string_literal: true

require 'test_helper'
require 'action_view'

module Tiered
  module Rails
    class ViewHelpersTest < Minitest::Test
      # Minimal view context that supports content_tag and the helpers under test.
      class TestViewContext
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::OutputSafetyHelper
        include Tiered::Rails::ViewHelpers

        def output_buffer
          @output_buffer ||= ActionView::OutputBuffer.new
        end

        attr_writer :output_buffer
      end

      def setup
        super
        @user = create_user
        @view = TestViewContext.new
      end

      def test_quota_severity_ok_within_limit
        assert_equal :ok, @view.quota_severity(:households, plan_owner: @user)
      end

      def test_quota_severity_blocked_when_exceeded_with_block_usage_policy
        create_household(user: @user)
        assert_equal :blocked, @view.quota_severity(:households, plan_owner: @user)
      end

      def test_tiered_quota_alert_empty_when_within_limit
        result = @view.tiered_quota_alert(quota: :households, plan_owner: @user)
        assert_equal '', result
      end

      def test_tiered_quota_alert_renders_html_when_exceeded
        create_household(user: @user)
        html = @view.tiered_quota_alert(quota: :households, plan_owner: @user)
        assert_includes html, 'plan-pay-quota-alert'
        assert_includes html, 'blocked'
      end

      def test_tiered_quota_meter_empty_when_unlimited
        Tiered.configure do |config|
          config.plan :unlimited_plan do |p|
            p.name 'Unlimited'
            p.price 0
            p.quota :households, to: :unlimited, type: :persistent, scope: lambda(&:households)
          end
        end
        @user.assign_plan!(:unlimited_plan)
        result = @view.tiered_quota_meter(quota: :households, plan_owner: @user)
        assert_equal '', result
      end

      def test_quota_remaining_returns_count
        assert_equal 1, @view.quota_remaining(:households, plan_owner: @user)
        create_household(user: @user)
        assert_equal 0, @view.quota_remaining(:households, plan_owner: @user)
      end

      def test_plan_allows_returns_correctly
        assert @view.plan_allows?(:split_type, :equal_parts, plan_owner: @user)
        refute @view.plan_allows?(:split_type, :percentage, plan_owner: @user)
      end
    end
  end
end
