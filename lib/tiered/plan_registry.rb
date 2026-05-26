# frozen_string_literal: true

module Tiered
  class PlanRegistry
    class << self
      def find(key)
        config.find_plan(key)
      end

      def all
        config.plans.values
      end

      def default
        default_key = config.default_plan
        return nil unless default_key

        config.find_plan(default_key) || all.first
      end

      private

      def config
        Tiered.configuration
      end
    end
  end
end
