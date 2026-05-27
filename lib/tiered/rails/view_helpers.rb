# frozen_string_literal: true

module Tiered
  module Rails
    module ViewHelpers
      def tiered_quota_alert(quota:, plan_owner:, **options)
        result = Services::QuotaChecker.check(plan_owner, quota)
        return '' if result.within_quota? || result.unlimited?

        css_class = options[:class] || 'tiered-quota-alert'
        severity = quota_severity(quota, plan_owner: plan_owner)
        message = quota_message(quota, plan_owner: plan_owner)

        render partial: 'tiered/quota_alert', locals: { css_class: css_class, severity: severity, message: message }
      end

      def tiered_quota_meter(quota:, plan_owner:, current: nil, max: nil, **options)
        result = Services::QuotaChecker.check(plan_owner, quota)
        current ||= result.current
        max ||= result.limit

        return '' if result.unlimited?

        percent = max.zero? ? 0 : (current.to_f / max * 100.0).round(2)
        percent = [percent, 100.0].min

        css_class = options[:class] || 'tiered-quota-meter'
        severity = quota_severity(quota, plan_owner: plan_owner)

        render partial: 'tiered/quota_meter',
               locals: { css_class: css_class, severity: severity, current: current, max: max,
                         percent: percent }
      end

      def quota_remaining(quota, plan_owner:)
        result = Services::QuotaChecker.check(plan_owner, quota)
        remaining = result.remaining
        remaining == Float::INFINITY ? '∞' : remaining
      end

      def quota_percent_used(quota, plan_owner:)
        result = Services::QuotaChecker.check(plan_owner, quota)
        result.percent_used
      end

      def quota_severity(quota, plan_owner:)
        result = Services::QuotaChecker.check(plan_owner, quota)
        return :ok if result.within_quota? || result.unlimited?

        plan = Services::PlanResolver.resolve(plan_owner)
        policy = plan&.after_quota_policy || :block_usage

        case policy
        when :block_usage
          :blocked
        when :grace_then_block
          quota_state = Models::QuotaState.find_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id,
            quota_key: quota
          )
          quota_state&.blocked? ? :blocked : :grace
        when :just_warn
          :warning
        else
          :warning
        end
      end

      def quota_message(quota, plan_owner:)
        result = Services::QuotaChecker.check(plan_owner, quota)
        return '' if result.within_quota? || result.unlimited?

        result.message || "Quota exceeded for #{quota}"
      end

      def plan_allows?(feature_key, value, plan_owner:)
        plan = Services::PlanResolver.resolve(plan_owner)
        plan&.allows_feature?(feature_key, value) || false
      end
    end
  end
end
