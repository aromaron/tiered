# frozen_string_literal: true

module PlanPay
  module Validators
    class FeatureValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return unless options[:quota_name]
        return unless options[:plan_owner]

        feature_key = options[:quota_name]
        plan_owner = resolve_plan_owner(record, options[:plan_owner])

        return unless plan_owner

        plan = Services::PlanResolver.resolve(plan_owner)
        return unless plan

        allowed = plan.allows_feature?(feature_key, value)
        return if allowed

        message = options[:message] || "Feature #{feature_key} with value #{value} is not allowed on your plan"
        record.errors.add(attribute, message)
      end

      private

      def resolve_plan_owner(record, plan_owner_option)
        if plan_owner_option.is_a?(Symbol) || plan_owner_option.is_a?(String)
          record.send(plan_owner_option)
        elsif plan_owner_option.is_a?(Proc)
          record.instance_eval(&plan_owner_option)
        else
          plan_owner_option
        end
      end
    end
  end
end
