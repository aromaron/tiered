# frozen_string_literal: true

module Tiered
  module Services
    class QuotaChecker
      class Result
        attr_reader :within_quota, :current, :limit, :quota_key, :quota_type, :message

        def initialize(within_quota:, current:, limit:, quota_key:, quota_type:, message: nil)
          @within_quota = within_quota
          @current = current
          @limit = limit
          @quota_key = quota_key
          @quota_type = quota_type
          @message = message
        end

        def within_quota?
          @within_quota
        end

        def exceeded?
          !@within_quota
        end

        def unlimited?
          @limit == Float::INFINITY
        end

        def remaining
          return Float::INFINITY if unlimited?
          return 0 if exceeded?

          @limit - @current
        end

        def percent_used
          return 0.0 if unlimited?
          return 100.0 if @limit.zero?

          (@current.to_f / @limit * 100.0).round(2)
        end
      end

      class << self
        def check(plan_owner, quota_key, plan: nil)
          plan ||= PlanResolver.resolve(plan_owner)
          quota_def = plan.quota_for(quota_key)

          unless quota_def
            return Result.new(
              within_quota: true,
              current: 0,
              limit: Float::INFINITY,
              quota_key: quota_key,
              quota_type: :none,
              message: "No quota defined for #{quota_key}"
            )
          end

          if quota_def[:type] == :persistent
            check_persistent_quota(plan_owner, quota_key, quota_def, plan)
          elsif quota_def[:type] == :per_period
            check_period_quota(plan_owner, quota_key, quota_def, plan)
          else
            raise Error, "Unknown quota type: #{quota_def[:type]}"
          end
        end

        private

        def check_persistent_quota(plan_owner, quota_key, quota_def, _plan)
          limit = quota_def[:to]

          scope = quota_def[:scope]
          unless scope
            raise Error, "Scope required for persistent quota #{quota_key}. Provide a scope in plan definition."
          end

          relation = scope.call(plan_owner)
          current = relation.respond_to?(:count) ? relation.count : 0
          within_quota = current < limit

          Result.new(
            within_quota: within_quota,
            current: current,
            limit: limit,
            quota_key: quota_key,
            quota_type: :persistent,
            message: within_quota ? nil : "Quota exceeded: #{current}/#{limit}"
          )
        end

        def check_period_quota(plan_owner, quota_key, quota_def, _plan)
          limit = quota_def[:to]
          period_type = quota_def[:per] || Tiered.configuration.period_cycle
          period = PeriodCalculator.calculate(period_type)

          usage = Models::Usage.find_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id,
            quota_key: quota_key,
            period_start: period[:start]
          )

          current = usage&.used || 0
          within_quota = current < limit

          Result.new(
            within_quota: within_quota,
            current: current,
            limit: limit,
            quota_key: quota_key,
            quota_type: :per_period,
            message: within_quota ? nil : "Period quota exceeded: #{current}/#{limit}"
          )
        end
      end
    end
  end
end
