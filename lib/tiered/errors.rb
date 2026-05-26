# frozen_string_literal: true

module Tiered
  class Error < StandardError; end

  class PlanNotFoundError < Error
    def initialize(plan_key)
      super("Plan not found: #{plan_key}")
    end
  end

  class QuotaExceededError < Error
    attr_reader :quota_key, :current, :limit

    def initialize(quota_key, current:, limit:)
      @quota_key = quota_key
      @current = current
      @limit = limit
      super("Quota exceeded for #{quota_key}: #{current}/#{limit}")
    end
  end

  class ConfigurationError < Error; end
end
