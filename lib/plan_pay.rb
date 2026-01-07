# frozen_string_literal: true

require_relative 'plan_pay/version'
require_relative 'plan_pay/errors'
require_relative 'plan_pay/configuration'
require_relative 'plan_pay/plan_definition'
require_relative 'plan_pay/plan_registry'
require_relative 'plan_pay/services/period_calculator'
require_relative 'plan_pay/services/plan_resolver'
require_relative 'plan_pay/services/quota_checker'
require_relative 'plan_pay/services/quota_enforcer'
require_relative 'plan_pay/services/consumption_tracker'
require_relative 'plan_pay/concerns/has_plan'
require_relative 'plan_pay/concerns/quota_limited'
require_relative 'plan_pay/rails/action_guards'
require_relative 'plan_pay/rails/view_helpers'
require_relative 'plan_pay/validators/count_validator'
require_relative 'plan_pay/validators/feature_validator'
require_relative 'plan_pay/validators/history_validator'

# Load ActiveRecord models if ActiveRecord is available
if defined?(ActiveRecord)
  require_relative 'plan_pay/models/assignment'
  require_relative 'plan_pay/models/quota_state'
  require_relative 'plan_pay/models/usage'
end

# Load Railtie for Rails integration
require_relative 'plan_pay/railtie' if defined?(Rails)

module PlanPay
  class << self
    def configure
      yield(configuration) if block_given?
    end

    def configuration
      @configuration ||= Configuration.new
    end

    attr_writer :configuration
  end
end
