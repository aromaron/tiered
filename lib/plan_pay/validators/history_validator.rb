# frozen_string_literal: true

module PlanPay
  module Validators
    class HistoryValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        return unless options[:quota_name]
        return unless options[:plan_owner]
        return unless value.is_a?(Time) || value.is_a?(Date) || value.is_a?(DateTime)

        quota_key = options[:quota_name]
        plan_owner = resolve_plan_owner(record, options[:plan_owner])

        return unless plan_owner

        plan = Services::PlanResolver.resolve(plan_owner)
        quota_def = plan&.quota_for(quota_key)
        return unless quota_def

        limit_months = quota_def[:to]
        return if limit_months == :unlimited

        cutoff_date = limit_months.months.ago
        return if value >= cutoff_date

        message = options[:message] || "Date must be within the last #{limit_months} months"
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
