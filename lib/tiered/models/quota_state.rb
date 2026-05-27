# frozen_string_literal: true

module Tiered
  module Models
    class QuotaState < ActiveRecord::Base
      self.table_name = 'tiered_quota_states'

      belongs_to :plan_owner, polymorphic: true

      validates :quota_key, presence: true
      validates :plan_owner_type, presence: true
      validates :quota_key, uniqueness: { scope: %i[plan_owner_type plan_owner_id] }

      scope :exceeded, -> { where.not(exceeded_at: nil) }
      scope :blocked, -> { where.not(blocked_at: nil) }
      scope :for_quota, ->(quota_key) { where(quota_key: quota_key) }

      def exceeded?
        exceeded_at.present?
      end

      def blocked?
        blocked_at.present?
      end

      def warned?
        last_warning_at.present?
      end
    end
  end
end
