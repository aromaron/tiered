# frozen_string_literal: true

require_relative 'tiered/version'
require_relative 'tiered/errors'
require_relative 'tiered/configuration'
require_relative 'tiered/plan_definition'
require_relative 'tiered/plan_registry'
require_relative 'tiered/services/period_calculator'
require_relative 'tiered/services/plan_resolver'
require_relative 'tiered/services/quota_checker'
require_relative 'tiered/services/quota_enforcer'
require_relative 'tiered/services/consumption_tracker'
require_relative 'tiered/concerns/has_plan'
require_relative 'tiered/concerns/quota_limited'
require_relative 'tiered/rails/action_guards'
require_relative 'tiered/rails/view_helpers'

# Load ActiveRecord models after active_record is fully initialized.
# on_load fires immediately when AR is already loaded (test env), deferred in Rails boot.
if defined?(ActiveSupport)
  ActiveSupport.on_load(:active_record) do
    require_relative 'tiered/models/assignment'
    require_relative 'tiered/models/quota_state'
    require_relative 'tiered/models/usage'
  end
elsif defined?(ActiveRecord)
  require_relative 'tiered/models/assignment'
  require_relative 'tiered/models/quota_state'
  require_relative 'tiered/models/usage'
end

# Load Engine for Rails integration
require_relative 'tiered/engine' if defined?(Rails)

module Tiered
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
