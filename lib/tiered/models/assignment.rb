# frozen_string_literal: true

module Tiered
  module Models
    class Assignment < ActiveRecord::Base
      self.table_name = 'tiered_assignments'

      belongs_to :plan_owner, polymorphic: true

      validates :plan_key, presence: true
      validates :source, presence: true
      validates :plan_owner_type, presence: true
      validates :plan_owner_id, presence: true
      validates :plan_owner_id, uniqueness: { scope: :plan_owner_type }

      scope :for_plan, ->(plan_key) { where(plan_key: plan_key) }
      scope :by_source, ->(source) { where(source: source) }
    end
  end
end
