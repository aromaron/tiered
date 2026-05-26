# frozen_string_literal: true

module Tiered
  module Concerns
    module HasPlan
      extend ActiveSupport::Concern

      included do
        has_many :tiered_assignments,
                 class_name: 'Tiered::Models::Assignment',
                 as: :plan_owner,
                 dependent: :destroy

        has_many :tiered_quota_states,
                 class_name: 'Tiered::Models::QuotaState',
                 as: :plan_owner,
                 dependent: :destroy

        has_many :tiered_usages,
                 class_name: 'Tiered::Models::Usage',
                 as: :plan_owner,
                 dependent: :destroy
      end

      def current_plan
        @current_plan ||= Services::PlanResolver.resolve(self)
      end

      def plan_key
        current_plan&.key
      end

      def plan_allows?(feature_key, value)
        current_plan&.allows_feature?(feature_key, value) || false
      end

      def within_quota?(quota_key)
        result = Services::QuotaChecker.check(self, quota_key)
        result.within_quota?
      end

      def quota_check(quota_key)
        Services::QuotaChecker.check(self, quota_key)
      end

      def plan_quota_for(quota_key)
        quota_def = current_plan&.quota_for(quota_key)
        quota_def&.dig(:to) || 0
      end

      def quota_remaining(quota_key)
        result = Services::QuotaChecker.check(self, quota_key)
        result.remaining
      end

      def quota_percent_used(quota_key)
        result = Services::QuotaChecker.check(self, quota_key)
        result.percent_used
      end

      def assign_plan!(plan_key, source: 'manual')
        @current_plan = nil # Clear cache
        Services::PlanResolver.assign_plan!(self, plan_key, source: source)
      end

      def remove_plan!
        @current_plan = nil # Clear cache
        Services::PlanResolver.remove_plan!(self)
      end

      def free_tier?
        plan = current_plan
        return false unless plan

        plan.price.zero?
      end

      def paid_tier?
        !free_tier?
      end

      def quota_severity(quota_key)
        result = Services::QuotaChecker.check(self, quota_key)
        return :ok if result.within_quota? || result.unlimited?

        policy = current_plan&.after_quota_policy || :block_usage

        case policy
        when :block_usage
          :blocked
        when :grace_then_block
          quota_state = tiered_quota_states.find_by(quota_key: quota_key)
          quota_state&.blocked? ? :blocked : :grace
        when :just_warn
          :warning
        else
          :warning
        end
      end

      def quota_message(quota_key)
        result = Services::QuotaChecker.check(self, quota_key)
        return '' if result.within_quota? || result.unlimited?

        result.message || "Quota exceeded for #{quota_key}"
      end
    end
  end
end
