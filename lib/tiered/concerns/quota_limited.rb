# frozen_string_literal: true

module Tiered
  module Concerns
    module QuotaLimited
      extend ActiveSupport::Concern

      included do
        # This concern is meant to be included in resource models
        # that are subject to quota limits (e.g., Household, Member, etc.)
      end

      class_methods do
        def quota_limited_by(quota_key, plan_owner:, scope: nil, error_after_quota: nil, if: nil)
          quota_key_sym = quota_key.to_sym
          condition_proc = binding.local_variable_get(:if)

          if condition_proc
            validate :check_quota_limit, on: :create, if: condition_proc
          else
            validate :check_quota_limit, on: :create
          end

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
            quota_def&.dig(:to) || 0
          end

          define_method :check_quota_limit do
            owner = plan_owner_for_quota
            return unless owner

            if scope
              quota_def = owner.current_plan&.quota_for(quota_key_sym)
              return unless quota_def

              limit = quota_def[:to]
              return if limit == Float::INFINITY

              relation = instance_eval(&scope)
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
