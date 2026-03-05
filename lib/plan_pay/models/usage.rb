# frozen_string_literal: true

module PlanPay
  module Models
    class Usage < ActiveRecord::Base
      self.table_name = 'plan_pay_usages'

      belongs_to :plan_owner, polymorphic: true

      validates :quota_key, presence: true
      validates :period_start, presence: true
      validates :plan_owner_type, presence: true
      validates :plan_owner_id, presence: true
      validates :quota_key, uniqueness: { scope: %i[plan_owner_type plan_owner_id period_start] }

      scope :for_quota, ->(quota_key) { where(quota_key: quota_key) }
      scope :for_period, lambda { |start_time, end_time = nil|
        scope = where(period_start: start_time)
        scope = scope.where(period_end: end_time) if end_time
        scope
      }
      scope :current_period, ->(start_time) { where(period_start: start_time) }

      def increment!(amount = 1)
        increment(:used, amount)
        touch(:last_used_at)
        save!
      end
    end
  end
end
