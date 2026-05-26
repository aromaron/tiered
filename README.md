# Tiered

Define and enforce pricing plan limits in your Rails application. Tiered helps you implement tiered pricing with usage quotas, feature restrictions, and period-based limits.

Extracted from a Personal Project and still under development. **Use this gem at your discretion since is not fully under maintenance** at the moment and serves more as a POC for my side projects.

## Installation

Install from GitHub:

```ruby
gem 'tiered', git: 'https://github.com/aromaron/tiered.git'
```

Or using a specific branch or tag:

```ruby
gem 'tiered', git: 'https://github.com/aromaron/tiered.git', branch: 'main'
# or
gem 'tiered', git: 'https://github.com/aromaron/tiered.git', tag: 'v0.1.0'
```

Then execute:

```bash
bundle install
```

Run the install generator to create the initializer and migrations:

```bash
rails generate tiered:install
rails db:migrate
```

## Configuration

Create an initializer at `config/initializers/tiered.rb`:

```ruby
Tiered.configure do |config|
  # Default plan for new users
  config.default_plan = :free
  
  # Period cycle for per-period quotas (:calendar_month, :billing_cycle)
  config.period_cycle = :calendar_month
  
  # How to resolve plan owner from controllers
  config.plan_owner_resolver = ->(controller) { controller.send(:current_user) }
end
```

### Defining Plans

Define your pricing tiers in the configuration:

```ruby
Tiered.configure do |config|
  config.plan :free do |plan|
    plan.name "Free"
    plan.description "Perfect for getting started"
    plan.price 0
    plan.price_string "Free"
    
    # Persistent quotas (counted resources)
    plan.quota :projects, to: 3, type: :persistent,
               scope: ->(user) { user.projects }
    
    plan.quota :team_members, to: 5, type: :persistent,
               scope: ->(user) { user.team_members }
    
    # Per-period quotas (monthly/weekly limits)
    plan.quota :api_calls, to: 1000, type: :per_period
    plan.quota :storage_gb, to: 5, type: :per_period
    
    # Feature restrictions
    plan.restrict :export_format, values: [:csv]
    plan.restrict :support_level, values: [:community]
    
    # Behavior when quota exceeded
    plan.after_quota_policy :block_usage
  end
  
  config.plan :pro do |plan|
    plan.name "Pro"
    plan.description "For growing teams"
    plan.price 2900  # $29.00 in cents
    plan.price_string "$29/mo"
    
    plan.quota :projects, to: :unlimited, type: :persistent
    plan.quota :team_members, to: 20, type: :persistent
    plan.quota :api_calls, to: 10000, type: :per_period
    plan.quota :storage_gb, to: 100, type: :per_period
    
    plan.restrict :export_format, values: [:csv, :pdf, :excel]
    plan.restrict :support_level, values: [:community, :email, :priority]
    
    plan.after_quota_policy :grace_then_block
    plan.grace_period_days 7
  end
end
```

## Usage

### Adding to Your User Model

Include the `HasPlan` concern in your user model:

```ruby
class User < ApplicationRecord
  include Tiered::Concerns::HasPlan
end
```

Now your users have plan-related methods:

```ruby
user = User.first

# Get current plan
user.current_plan        # => Tiered::PlanDefinition
user.plan_key            # => :free

# Check quotas
user.within_quota?(:projects)      # => true/false
user.quota_remaining(:projects)    # => 2
user.quota_percent_used(:projects) # => 33.33

# Check feature restrictions
user.plan_allows?(:export_format, :pdf)  # => false for free tier
user.plan_allows?(:support_level, :email) # => false for free tier

# Assign/change plans
user.assign_plan!(:pro, source: 'stripe')
user.remove_plan!

# Check tier
user.free_tier?  # => true/false
user.paid_tier?  # => true/false
```

### Enforcing Quotas on Models

Use the `QuotaLimited` concern to enforce limits when creating records:

```ruby
class Project < ApplicationRecord
  include Tiered::Concerns::QuotaLimited

  belongs_to :user

  quota_limited_by :projects,
    plan_owner: :user,
    error_after_quota: "You've reached your project limit. Upgrade to create more."
end
```

### Enforcing in Controllers

Use action guards to protect controller actions:

```ruby
class ApiController < ApplicationController
  include Tiered::Rails::ActionGuards
  
  # Set the plan owner method (defaults to current_user)
  tiered_plan_owner_method :current_user
  
  # Guard specific actions
  guard_action :create, quota: :projects
  guard_action :upload, quota: :storage_gb
  
  # Custom redirect on blocked
  tiered_redirect_on_blocked_limit ->(result) {
    redirect_to pricing_path, alert: result.message
  }
end
```

### Tracking Per-Period Usage

For per-period quotas (like API calls), track usage:

```ruby
# In your API controller
before_action :track_api_usage

private

def track_api_usage
  Tiered::Services::ConsumptionTracker.track(
    current_user,
    :api_calls,
    by: 1
  )
end
```

### Feature Restrictions in Models

Validate feature restrictions in your models:

```ruby
class Report < ApplicationRecord
  belongs_to :user
  
  validate :export_format_allowed
  
  private
  
  def export_format_allowed
    return unless export_format.present?
    
    unless user.plan_allows?(:export_format, export_format.to_sym)
      errors.add(:export_format, "not available on your plan")
    end
  end
end
```

## Quota Types

### Persistent Quotas

Counted resources that persist until deleted (e.g., projects, team members).

```ruby
plan.quota :projects, to: 5, type: :persistent,
           scope: ->(user) { user.projects }
```

### Per-Period Quotas

Usage limits that reset each period (e.g., API calls, uploads).

```ruby
plan.quota :api_calls, to: 1000, type: :per_period
```

## After-Quota Policies

Control behavior when quotas are exceeded:

- `:block_usage` - Prevent further usage (default)
- `:grace_then_block` - Allow grace period, then block
- `:just_warn` - Allow usage but return a warning message

```ruby
plan.after_quota_policy :grace_then_block
plan.grace_period_days 7
```

## Advanced Usage

### Custom Quota Checking

```ruby
result = user.quota_check(:api_calls)
result.within_quota?  # => true/false
result.exceeded?      # => true/false
result.remaining      # => 234
result.percent_used   # => 76.6
```

### Programmatic Plan Assignment

```ruby
# Assign with source tracking
user.assign_plan!(:pro, source: 'stripe_subscription_123')

# Check assignment history
user.tiered_assignments.order(created_at: :desc)

# Remove plan (falls back to default)
user.remove_plan!
```

### View Helpers

```erb
<% if current_user.within_quota?(:projects) %>
  <%= link_to "New Project", new_project_path %>
<% else %>
  <p>Upgrade to create more projects</p>
<% end %>

<%= tiered_quota_meter(quota: :storage_gb, plan_owner: current_user) %>
```

## Testing

Configure test-specific plans in your test helper:

```ruby
# test/test_helper.rb
Tiered.configure do |config|
  config.plan :test do |plan|
    plan.name "Test"
    plan.quota :projects, to: 100, type: :persistent,
               scope: ->(user) { user.projects }
  end
end
```

## Using in CI/CD

### GitHub Actions

For private repositories, GitHub Actions has automatic access. For public repos accessing this private gem, use a deploy key or personal access token:

```yaml
# .github/workflows/ci.yml
- name: Checkout code
  uses: actions/checkout@v4
  with:
    ssh-key: ${{ secrets.SSH_PRIVATE_KEY }}

- name: Setup Ruby
  uses: ruby/setup-ruby@v1
  with:
    ruby-version: '3.2'
    bundler-cache: true
```

Or using HTTPS with a token:

```yaml
- name: Configure git for private gems
  run: |
    git config --global url."https://${{ secrets.GH_PAT }}@github.com/".insteadOf "https://github.com/"

- name: Bundle install
  run: bundle install
```

### Railway Deployment

For Railway, add the GitHub token as an environment variable:

```bash
# In Railway dashboard or CLI
railway variables set BUNDLE_GITHUB__COM=${GH_PAT}:x-oauth-basic
```

Or use a build command:

```dockerfile
# Dockerfile
ARG GH_PAT
RUN bundle config set --global https://github.com/.extraheader "Authorization: Bearer ${GH_PAT}" \
    && bundle install
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`.

To create a new release (tag and build), update the version number in `version.rb`, and then run `bundle exec rake build` to create the `.gem` file. Push the tag to GitHub for version tracking.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aromaron/tiered.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
