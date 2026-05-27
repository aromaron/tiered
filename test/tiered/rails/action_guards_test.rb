# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Rails
    class ActionGuardsTest < Minitest::Test
      # Minimal stub that includes ActionGuards without a full HTTP stack.
      # Uses tiered_plan_owner_method to wire the owner resolver via the gem's own API.
      class StubController
        include Tiered::Rails::ActionGuards

        attr_writer :plan_owner

        tiered_plan_owner_method :current_owner

        def current_owner
          @plan_owner
        end

        def responses
          @responses ||= []
        end

        def head(status)
          responses << { head: status }
        end

        def redirect_to(path, **opts)
          responses << { redirect_to: path }.merge(opts)
        end
      end

      def setup
        super
        @user = create_user
        @controller = StubController.new
        @controller.plan_owner = @user
      end

      def test_enforce_quota_allows_when_within_limit
        @controller.send(:enforce_quota!, :households)

        assert_empty @controller.responses
      end

      def test_enforce_quota_blocks_when_exceeded
        create_household(user: @user) # puts user at limit (1/1)
        @controller.send(:enforce_quota!, :households)

        assert_equal 1, @controller.responses.length
        assert_equal :forbidden, @controller.responses.first[:head]
      end

      def test_enforce_quota_uses_custom_redirect_handler
        create_household(user: @user)
        @controller.class.tiered_redirect_on_blocked_limit(lambda { |result|
          redirect_to '/pricing', alert: result.message
        })
        @controller.send(:enforce_quota!, :households)

        assert_equal '/pricing', @controller.responses.first[:redirect_to]
      ensure
        @controller.class.remove_method :tiered_redirect_on_blocked_limit
      end

      def test_tiered_plan_owner_method_wires_custom_resolver
        # Use an anonymous class to avoid polluting StubController
        klass = Class.new do
          include Tiered::Rails::ActionGuards

          tiered_plan_owner_method :fetch_owner
          define_method(:fetch_owner) { 'the_owner' }
          def head(*); end
          def redirect_to(*); end
        end

        assert_equal 'the_owner', klass.new.tiered_plan_owner
      end
    end
  end
end
