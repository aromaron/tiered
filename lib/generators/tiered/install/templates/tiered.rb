# frozen_string_literal: true

Tiered.configure do |config|
  # Set the default plan for new users
  config.default_plan = :free

  # Set the period cycle for per-period quotas
  # Options: :calendar_month, :calendar_week, :calendar_day
  config.period_cycle = :calendar_month

  # Define how to resolve the plan owner from a controller
  # config.plan_owner_resolver = ->(controller) { controller.current_user }

  # Define what happens when a quota is blocked
  # config.redirect_on_blocked_limit = ->(result) {
  #   redirect_to pricing_path, alert: result.message
  # }

  # Define plans
  config.plan :free do |free|
    free.name 'Free'
    free.description 'Perfect for getting started'
    free.price 0
    free.price_string 'Free'

    # Example quotas - customize for your app
    # free.quota :households, to: 1, per: nil, type: :persistent
    # free.quota :members, to: 4, per: nil, type: :persistent
    # free.quota :api_calls, to: 1000, per: :month, type: :per_period

    # Example feature restrictions
    # free.restrict :split_type, values: [:equal_parts]

    free.after_quota_policy :block_usage
  end

  # config.plan :plus do |plus|
  #   plus.name "Plus"
  #   plus.description "For growing teams"
  #   plus.price 99
  #   plus.price_string "$99/mo"
  #
  #   plus.quota :households, to: 3, per: nil, type: :persistent
  #   plus.after_quota_policy :grace_then_block
  #   plus.grace_period_days 7
  # end
end
