# frozen_string_literal: true

module Tiered
  module Rails
    module ActionGuards
      extend ActiveSupport::Concern

      class_methods do
        def guard_action(action_name, quota:)
          before_action(only: [action_name]) { enforce_quota!(quota) }
        end

        def tiered_plan_owner_method(method_name)
          define_method :tiered_plan_owner do
            send(method_name)
          end
        end

        def tiered_redirect_on_blocked_limit(path_or_proc)
          define_method :tiered_redirect_on_blocked_limit do |result|
            if path_or_proc.is_a?(Proc)
              instance_exec(result, &path_or_proc)
            else
              redirect_to path_or_proc, alert: result.message
            end
          end
        end
      end

      private

      def tiered_plan_owner
        # Default: try to get from configuration or use current_user
        resolver = Tiered.configuration.plan_owner_resolver
        if resolver
          resolver.call(self)
        elsif respond_to?(:current_user, true)
          current_user
        else
          raise Error, 'No plan owner resolver configured and no current_user method found'
        end
      end

      def tiered_redirect_on_blocked_limit(result)
        # Default redirect handler
        redirect_handler = Tiered.configuration.redirect_on_blocked_limit
        if redirect_handler
          instance_exec(result, &redirect_handler)
        else
          head :forbidden
        end
      end

      def enforce_quota!(quota_key)
        owner = tiered_plan_owner
        return unless owner

        # Use QuotaEnforcer to handle all policies consistently
        enforce_result = Services::QuotaEnforcer.enforce(owner, quota_key)
        return if enforce_result.allowed?

        # Quota blocked - redirect or return error
        tiered_redirect_on_blocked_limit(enforce_result)
      end
    end
  end
end
