# frozen_string_literal: true

module PlanPay
  module Services
    class QuotaEnforcer
      class Result
        attr_reader :allowed, :message, :policy, :quota_key

        def initialize(allowed:, policy:, quota_key:, message: nil)
          @allowed = allowed
          @message = message
          @policy = policy
          @quota_key = quota_key
        end

        def allowed?
          @allowed
        end

        def blocked?
          !@allowed
        end
      end

      class << self
        def enforce(plan_owner, quota_key, plan: nil)
          plan ||= PlanResolver.resolve(plan_owner)
          quota_def = plan.quota_for(quota_key)

          unless quota_def
            return Result.new(
              allowed: true,
              policy: :none,
              quota_key: quota_key,
              message: 'No quota defined'
            )
          end

          check_result = QuotaChecker.check(plan_owner, quota_key, plan: plan)

          if check_result.within_quota? || check_result.unlimited?
            return Result.new(
              allowed: true,
              policy: plan.after_quota_policy,
              quota_key: quota_key
            )
          end

          # Quota exceeded - apply policy
          policy = plan.after_quota_policy || :block_usage

          case policy
          when :block_usage
            Result.new(
              allowed: false,
              message: check_result.message || "Quota exceeded for #{quota_key}",
              policy: policy,
              quota_key: quota_key
            )
          when :grace_then_block
            enforce_grace_period(plan_owner, quota_key, check_result, plan)
          when :just_warn
            Result.new(
              allowed: true,
              message: check_result.message || "Warning: Quota exceeded for #{quota_key}",
              policy: policy,
              quota_key: quota_key
            )
          else
            raise Error, "Unknown policy: #{policy}"
          end
        end

        private

        def enforce_grace_period(plan_owner, quota_key, _check_result, plan)
          grace_days = plan.grace_period_days || PlanPay.configuration.grace_period_days || 7

          quota_state = Models::QuotaState.find_or_initialize_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id,
            quota_key: quota_key
          )

          # Check if already in grace period
          if quota_state.exceeded_at
            grace_end = quota_state.exceeded_at + grace_days.days
            if Time.current < grace_end
              # Still in grace period
              return Result.new(
                allowed: true,
                message: "In grace period until #{grace_end}",
                policy: :grace_then_block,
                quota_key: quota_key
              )
            else
              # Grace period expired
              quota_state.blocked_at ||= Time.current
              quota_state.save!
              return Result.new(
                allowed: false,
                message: "Grace period expired. Quota blocked for #{quota_key}",
                policy: :grace_then_block,
                quota_key: quota_key
              )
            end
          end

          # First time exceeding - start grace period
          quota_state.exceeded_at = Time.current
          quota_state.save!

          Result.new(
            allowed: true,
            message: "Grace period started. Quota will be blocked in #{grace_days} days",
            policy: :grace_then_block,
            quota_key: quota_key
          )
        end
      end
    end
  end
end
