# frozen_string_literal: true

module Tiered
  class Configuration
    attr_accessor :default_plan, :period_cycle, :plan_owner_resolver, :redirect_on_blocked_limit, :grace_period_days

    def initialize
      @default_plan = :free
      @period_cycle = :calendar_month
      @plan_owner_resolver = nil
      @redirect_on_blocked_limit = nil
      @grace_period_days = 7
      @plans = {}
    end

    def plan(key)
      plan_def = PlanDefinition.new(key)
      yield(plan_def) if block_given?
      @plans[key.to_sym] = plan_def
    end

    attr_reader :plans

    def find_plan(key)
      @plans[key.to_sym]
    end
  end
end
