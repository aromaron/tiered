# frozen_string_literal: true

module PlanPay
  module Services
    class PlanResolver
      class << self
        def resolve(plan_owner)
          # Resolution order: subscription → manual → default
          # v1.0: Only manual and default (subscription support in v1.1+)

          # 1. Check for manual assignment
          assignment = Models::Assignment.find_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id
          )

          if assignment
            plan = PlanRegistry.find(assignment.plan_key)
            return plan if plan
          end

          # 2. Fall back to default plan
          default_plan = PlanRegistry.default
          unless default_plan
            raise ConfigurationError,
                  'No default plan configured. Set PlanPay.configuration.default_plan'
          end

          default_plan
        end

        def assign_plan!(plan_owner, plan_key, source: 'manual')
          plan = PlanRegistry.find(plan_key)
          raise PlanNotFoundError, plan_key unless plan

          assignment = Models::Assignment.find_or_initialize_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id
          )

          assignment.plan_key = plan_key
          assignment.source = source
          assignment.save!
          assignment
        end

        def remove_plan!(plan_owner)
          assignment = Models::Assignment.find_by(
            plan_owner_type: plan_owner.class.name,
            plan_owner_id: plan_owner.id
          )

          assignment&.destroy!
        end
      end
    end
  end
end
