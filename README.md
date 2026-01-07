# PlanPay

**Plan and pay for Rails apps**

A comprehensive Rails gem for billing integration, subscription management, and feature gating. Born from [RumiPay](#).

## Status

🚧 **Planning Phase** → Moving to Implementation (v1.0)

This gem is currently in active development. The core architecture and data model have been designed. See the [documentation](./docs/) for detailed proposals and implementation plans.

## Features

### v1.0 - Free Tier & Limits (MVP) - 🎯 Current Focus

- ✅ Plan management and registry
- ✅ Quota system (persistent caps and per-period allowances)
- ✅ Feature gating and restrictions
- ✅ Usage tracking
- ✅ Rails integration (model mixins, controller guards, view helpers)
- ✅ Quota enforcement (block, grace period, or warn)

### v1.1 - Subscription Management (Planned)

- Payment processor integration (Stripe, Pay, RailsBilling)
- Grace periods and trials
- Plan upgrades/downgrades
- Overage reporting

### v2.0 - Advanced Features (Planned)

- Event system (RailsEventStore adapter)
- Advanced period calculations
- Background job enforcement

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plan_pay'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install plan_pay
```

## Quick Start

### 1. Install the gem

```bash
bundle add plan_pay
```

### 2. Run the generator

```bash
rails generate plan_pay:install
```

This will create:
- Migration files for `plan_pay_assignments`, `plan_pay_quota_states`, and `plan_pay_usages` tables
- Initializer file at `config/initializers/plan_pay.rb`

### 3. Configure your plans

```ruby
# config/initializers/plan_pay.rb

PlanPay.configure do |config|
  config.default_plan = :free
  
  config.plan :free do |free|
    free.name "Free"
    free.quota :households, to: 1, per: nil, type: :persistent
    free.quota :members, to: 4, per: nil, type: :persistent
    free.after_quota_policy :block_usage
  end
  
  config.plan :plus do |plus|
    plus.name "Plus"
    plus.price 99
    plus.quota :households, to: 3, per: nil, type: :persistent
    plus.quota :members, to: 8, per: nil, type: :persistent
    plus.after_quota_policy :grace_then_block
    plus.grace_period_days 7
  end
end
```

### 4. Add to your models

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include PlanPay::HasPlan
end

# app/models/household.rb
class Household < ApplicationRecord
  include PlanPay::QuotaLimited
  
  quota_key :households
end
```

### 5. Use in controllers

```ruby
# app/controllers/households_controller.rb
class HouseholdsController < ApplicationController
  include PlanPay::ActionGuards
  
  guard_action :create, quota: :households
  
  def create
    # Your create logic
  end
end
```

## Documentation

Comprehensive documentation is available in the `docs/` directory:

- **[BILLING_PLANS_GEM_PROPOSAL.md](./docs/BILLING_PLANS_GEM_PROPOSAL.md)** - Complete architecture, data model, configuration DSL, and usage examples
- **[PRICING_PLANS_REVIEW.md](./docs/PRICING_PLANS_REVIEW.md)** - Analysis of the pricing_plans gem and useful patterns
- **[PLAN_LIMITS_GEM_PROPOSAL.md](./docs/PLAN_LIMITS_GEM_PROPOSAL.md)** - Initial proposal document

## Architecture Overview

PlanPay provides:

1. **Plan Management**: Define plans with quotas, features, and pricing
2. **Quota System**: Track and enforce limits (count-based, per-period, feature restrictions)
3. **Subscription Management**: Integrate with payment processors (v1.1+)
4. **Rails Integration**: Mixins, guards, helpers, and validators for seamless integration

### Core Components

- `PlanRegistry` - Plan definitions and lookup
- `PlanResolver` - Resolve user's active plan (subscription → manual → default)
- `QuotaChecker` - Check if quotas are within limits
- `QuotaEnforcer` - Enforce quota policies (block, grace, warn)
- `HasPlan` - Mixin for User/Organization models
- `QuotaLimited` - Mixin for resource models
- `ActionGuards` - Controller guards for quota enforcement

## Requirements

- Ruby >= 4.0.0
- Rails >= 7.1
- ActiveRecord
- ActiveSupport

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/yourusername/plan_pay/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Origin

PlanPay was born from [RumiPay](https://github.com/yourusername/rumipay), extracted to provide a reusable solution for plan management, subscriptions, and feature gating in Rails applications.
