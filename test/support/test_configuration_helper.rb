# frozen_string_literal: true

module TestConfigurationHelper
  def setup
    super
    reset_configuration!
    setup_test_plans
  end

  def teardown
    super
    cleanup_test_data
  end

  def reset_configuration!
    Tiered.configuration = Tiered::Configuration.new
  end

  def setup_test_plans
    Tiered.configure do |config|
      config.default_plan = :free

      config.plan :free do |free|
        free.name 'Free'
        free.description 'Free plan'
        free.price 0
        free.price_string 'Free'

        free.quota :households, to: 1, per: nil, type: :persistent,
                                scope: lambda(&:households)
        free.quota :api_calls, to: 100, per: :month, type: :per_period

        free.restrict :split_type, values: %i[equal_parts]

        free.after_quota_policy :block_usage
      end

      config.plan :plus do |plus|
        plus.name 'Plus'
        plus.description 'Plus plan'
        plus.price 99
        plus.price_string '$99/mo'

        plus.quota :households, to: 3, per: nil, type: :persistent,
                                scope: lambda(&:households)
        plus.quota :api_calls, to: 1000, per: :month, type: :per_period

        plus.after_quota_policy :grace_then_block
        plus.grace_period_days 7
      end
    end
  end

  def create_user(attributes = {})
    User.create!({ name: 'Test User' }.merge(attributes))
  end

  def create_household(user:, **attributes)
    Household.create!({ user: user, name: 'Household 1' }.merge(attributes))
  end

  def travel_to_time(time, &)
    Time.stub(:current, time, &)
  end

  def cleanup_test_data
    Tiered::Models::Assignment.delete_all
    Tiered::Models::QuotaState.delete_all
    Tiered::Models::Usage.delete_all
    User.delete_all
    Household.delete_all
  end
end
