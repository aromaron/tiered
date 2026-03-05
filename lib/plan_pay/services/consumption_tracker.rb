# frozen_string_literal: true

module PlanPay
  module Services
    class ConsumptionTracker
      class << self
        def track(plan_owner, quota_key, amount: 1, period_type: nil)
          plan = PlanResolver.resolve(plan_owner)
          quota_def = plan&.quota_for(quota_key)

          return unless quota_def
          return unless quota_def[:type] == :per_period

          period_type ||= quota_def[:per] || PlanPay.configuration.period_cycle
          period = PeriodCalculator.calculate(period_type)

          usage = Models::Usage.find_or_initialize_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id,
            quota_key: quota_key,
            period_start: period[:start]
          )

          usage.period_end = period[:end] if period[:end]
          usage.save! if usage.new_record?
          usage.increment!(amount)

          usage
        end

        def reset(plan_owner, quota_key, period_type: nil)
          plan = PlanResolver.resolve(plan_owner)
          quota_def = plan&.quota_for(quota_key)

          return unless quota_def
          return unless quota_def[:type] == :per_period

          period_type ||= quota_def[:per] || PlanPay.configuration.period_cycle
          period = PeriodCalculator.calculate(period_type)

          usage = Models::Usage.find_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id,
            quota_key: quota_key,
            period_start: period[:start]
          )

          usage&.update(used: 0, last_used_at: nil)

          usage
        end
      end
    end
  end
end
