# frozen_string_literal: true

module PlanPay
  module Validators
    class CountValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, _value)
        return unless options[:quota_name]
        return unless options[:plan_owner]

        quota_key = options[:quota_name]
        plan_owner = resolve_plan_owner(record, options[:plan_owner])

        return unless plan_owner

        result = Services::QuotaChecker.check(plan_owner, quota_key)
        return if result.within_quota? || result.unlimited?

        message = options[:message] || result.message || "Quota exceeded for #{quota_key}"
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
