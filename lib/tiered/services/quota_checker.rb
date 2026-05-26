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
          @limit == :unlimited
        end

        def remaining
          return :unlimited if unlimited?
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
              limit: :unlimited,
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
          if limit == :unlimited
            return Result.new(
              within_quota: true,
              current: 0,
              limit: :unlimited,
              quota_key: quota_key,
              quota_type: :persistent
            )
          end

          # Use scope if provided, otherwise count directly
          scope = quota_def[:scope]
          unless scope
            raise Error, "Scope required for persistent quota #{quota_key}. Provide a scope in plan definition."
          end

          # Scope is a lambda that takes the plan_owner and returns a relation
          relation = scope.call(plan_owner)
          current = relation.respond_to?(:count) ? relation.count : 0

          # Default: count records with quota_key matching the plan_owner
          # This is a simplified version - apps should provide scopes
          # For v1.0, we require scopes to be provided for persistent quotas

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
          if limit == :unlimited
            return Result.new(
              within_quota: true,
              current: 0,
              limit: :unlimited,
              quota_key: quota_key,
              quota_type: :per_period
            )
          end

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
