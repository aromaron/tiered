# frozen_string_literal: true

module Tiered
  class PlanDefinition
    attr_reader :key, :quotas, :restrictions

    def name(value = nil)
      return @name if value.nil?

      @name = value
    end

    def description(value = nil)
      return @description if value.nil?

      @description = value
    end

    def price(value = nil)
      return @price if value.nil?

      @price = value
    end

    def price_string(value = nil)
      return @price_string if value.nil?

      @price_string = value
    end

    def after_quota_policy(value = nil)
      return @after_quota_policy if value.nil?

      @after_quota_policy = value
    end

    def grace_period_days(value = nil)
      return @grace_period_days if value.nil?

      @grace_period_days = value
    end

    def initialize(key)
      @key = key.to_sym
      @name = nil
      @description = nil
      @price = 0
      @price_string = nil
      @after_quota_policy = :block_usage
      @grace_period_days = nil
      @quotas = {}
      @restrictions = {}
    end

    def quota(quota_key, to:, per: nil, type: :persistent, scope: nil)
      @quotas[quota_key.to_sym] = {
        to: to == :unlimited ? Float::INFINITY : to,
        per: per,
        type: type,
        scope: scope
      }
    end

    def restrict(feature_key, values:)
      @restrictions[feature_key.to_sym] = { values: values }
    end

    def quota_for(quota_key)
      @quotas[quota_key.to_sym]
    end

    def restriction_for(feature_key)
      @restrictions[feature_key.to_sym]
    end

    def allows_feature?(feature_key, value)
      restriction = restriction_for(feature_key)
      return true unless restriction

      restriction[:values].include?(value)
    end

    def unlimited_quota?(quota_key)
      quota = quota_for(quota_key)
      return false unless quota

      quota[:to] == Float::INFINITY
    end
  end
end
