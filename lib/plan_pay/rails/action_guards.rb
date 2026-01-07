# frozen_string_literal: true

module PlanPay
  module Rails
    module ActionGuards
      extend ActiveSupport::Concern

      included do
        class_attribute :_plan_pay_guards, default: {}
      end

      class_methods do
        def guard_action(action_name, quota:, plan_owner: nil, by: 1)
          _plan_pay_guards[action_name.to_sym] = {
            quota: quota.to_sym,
            plan_owner: plan_owner,
            by: by
          }

          before_action :"enforce_#{quota}_quota!", only: [action_name]
        end

        def plan_pay_plan_owner_method(method_name)
          define_method :plan_pay_plan_owner do
            send(method_name)
          end
        end

        def plan_pay_redirect_on_blocked_limit(path_or_proc)
          define_method :plan_pay_redirect_on_blocked_limit do |result|
            if path_or_proc.is_a?(Proc)
              instance_exec(result, &path_or_proc)
            else
              redirect_to path_or_proc, alert: result.message
            end
          end
        end
      end

      private

      def plan_pay_plan_owner
        # Default: try to get from configuration or use current_user
        resolver = PlanPay.configuration.plan_owner_resolver
        if resolver
          resolver.call(self)
        elsif respond_to?(:current_user, true)
          current_user
        else
          raise Error, 'No plan owner resolver configured and no current_user method found'
        end
      end

      def plan_pay_redirect_on_blocked_limit(result)
        # Default redirect handler
        redirect_handler = PlanPay.configuration.redirect_on_blocked_limit
        if redirect_handler
          instance_exec(result, &redirect_handler)
        else
          head :forbidden
        end
      end

      def method_missing(method_name, *args, &)
        if method_name.to_s.start_with?('enforce_') && method_name.to_s.end_with?('_quota!')
          quota_key = method_name.to_s.gsub(/^enforce_/, '').gsub(/_quota!$/, '').to_sym
          enforce_quota!(quota_key)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        if method_name.to_s.start_with?('enforce_') && method_name.to_s.end_with?('_quota!')
          true
        else
          super
        end
      end

      def enforce_quota!(quota_key)
        owner = plan_pay_plan_owner
        return unless owner

        # Use QuotaEnforcer to handle all policies consistently
        enforce_result = Services::QuotaEnforcer.enforce(owner, quota_key)
        return if enforce_result.allowed?

        # Quota blocked - redirect or return error
        plan_pay_redirect_on_blocked_limit(enforce_result)
      end
    end
  end
end
