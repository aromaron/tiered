# frozen_string_literal: true

module PlanPay
  module Concerns
    module QuotaLimited
      extend ActiveSupport::Concern

      included do
        # This concern is meant to be included in resource models
        # that are subject to quota limits (e.g., Household, Member, etc.)
      end

      class_methods do
        def quota_limited_by(quota_key, plan_owner:, count_scope: nil, to: nil, per: nil, error_after_quota: nil, if: nil)
          # NOTE: to and per are part of the API but handled by the plan definition
          _to = to
          _per = per
          quota_key_sym = quota_key.to_sym
          condition_proc = binding.local_variable_get(:if)

          # Add validation with optional condition
          if condition_proc
            validate :check_quota_limit, on: :create, if: condition_proc
          else
            validate :check_quota_limit, on: :create
          end

          # Define instance methods
          define_method :plan_owner_for_quota do
            if plan_owner.is_a?(Proc)
              instance_eval(&plan_owner)
            else
              send(plan_owner)
            end
          end

          define_method :quota_key_for_resource do
            quota_key_sym
          end

          define_method :quota_limit_for_resource do
            owner = plan_owner_for_quota
            return 0 unless owner

            quota_def = owner.current_plan&.quota_for(quota_key_sym)
            limit = quota_def&.dig(:to) || 0
            limit == :unlimited ? Float::INFINITY : limit
          end

          define_method :count_scope_for_quota do
            count_scope
          end

          define_method :check_quota_limit do
            owner = plan_owner_for_quota
            return unless owner

            # If count_scope is provided, use it for per-resource quotas
            # Otherwise use QuotaChecker with plan-defined scope
            if count_scope
              quota_def = owner.current_plan&.quota_for(quota_key_sym)
              return unless quota_def

              limit = quota_def[:to]
              return if limit == :unlimited

              # count_scope is evaluated with self (the instance) as context
              relation = instance_eval(&count_scope)
              current = relation.respond_to?(:count) ? relation.count : 0

              return if current < limit

              error_message = if error_after_quota.is_a?(Proc)
                                instance_eval(&error_after_quota)
                              elsif error_after_quota
                                error_after_quota
                              else
                                "Quota limit exceeded for #{quota_key_sym}: #{current}/#{limit}"
                              end

              errors.add(:base, error_message)
            else
              result = Services::QuotaChecker.check(owner, quota_key_sym)
              return if result.within_quota? || result.unlimited?

              error_message = if error_after_quota.is_a?(Proc)
                                instance_eval(&error_after_quota)
                              elsif error_after_quota
                                error_after_quota
                              else
                                "Quota limit exceeded for #{quota_key_sym}: #{result.current}/#{result.limit}"
                              end

              errors.add(:base, error_message)
            end
          end
        end
      end
    end
  end
end
