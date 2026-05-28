# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-05-28

### Fixed
- `rails generate tiered:install` produced doubled timestamp prefixes in migration filenames (e.g. `20260528_20260528_create_tiered_assignments.rb`). Migration destination paths no longer include a manual prefix — `ActiveRecord::Generators::Migration` handles timestamping automatically.
- UUID auto-detection in the install generator always returned `false` because `Rails` inside `module Tiered::Rails` resolved to the gem's own namespace. Fixed by using the absolute constant `::Rails`.

### Changed
- Install generator auto-detects UUID primary keys from `Rails.application.config.generators` and emits `id: :uuid` / `type: :uuid` in migrations when detected. Pass `--uuid` or `--no-uuid` to override.
- All compound indexes in generated migrations now carry explicit `name:` values (short `idx_` prefix) to avoid PostgreSQL's 63-character limit and ensure predictable names across apps.
- Removed the PostgreSQL-only partial index (`WHERE exceeded_at IS NOT NULL`) from the `tiered_quota_states` migration template — replaced with a plain index that works on all adapters.

## [0.3.0] - 2026-05-27

### Breaking Changes
- `quota_limited_by` kwarg renamed: `count_scope:` → `scope:` (consistent with the plan DSL's `scope:` kwarg).
- `:billing_cycle` removed from `PeriodCalculator` — it was identical to `:calendar_month`. Use `:calendar_month` instead.
- `Tiered::Railtie` replaced by `Tiered::Engine`. Direct references to `Tiered::Railtie` must be updated.
- `guard_action` dropped the undocumented `plan_owner:` keyword argument (it was accepted but never used).

### Added
- `app/views/tiered/_quota_alert.html.erb` and `_quota_meter.html.erb` — host apps can override by placing replacement files under their own `app/views/tiered/`.
- RuboCop (`rubocop`, `rubocop-minitest`, `rubocop-rails`) with `.rubocop.yml`; lint CI job added.
- SimpleCov coverage reporting (90% line coverage baseline).

### Changed
- `Float::INFINITY` replaces the `:unlimited` symbol sentinel throughout. `quota[:to]` is now always numeric; `Result#unlimited?` checks `limit == Float::INFINITY`. The DSL still accepts `to: :unlimited` and normalizes it at definition time.
- `Railtie` promoted to `Engine` — `app/views` is automatically added to the host app's view path, enabling partial overrides.
- `tiered_quota_alert` and `tiered_quota_meter` now render ERB partials instead of building HTML inline in Ruby.
- CSS class names corrected from `plan-pay-quota-alert` / `plan-pay-quota-meter` to `tiered-quota-alert` / `tiered-quota-meter`.
- `guard_action` installs a direct `before_action` block; the `method_missing` dispatch is removed.

## [0.2.0] - 2026-05-26

### Fixed
- `quota_severity` returned `:warning` for `:block_usage` policy due to a dead expression discarding the policy value. Now correctly returns `:blocked`.
- `QuotaChecker.check` created a `tiered_usages` row as a side effect on every read. Checks are now read-only; row creation is confined to `ConsumptionTracker.track`.
- `Usage.increment!` used read-modify-write, causing lost increments under concurrent requests. Replaced with an atomic `update_all('used = used + ?')` via `Usage.bump`.
- Model autoload now uses `ActiveSupport.on_load(:active_record)` so models load after AR is fully initialized during Rails boot.

### Changed
- `ConsumptionTracker.track` keyword argument renamed from `amount:` to `by:` (matches documented API).
- `quota_limited_by` removed undocumented `to:` and `per:` kwargs that were silently discarded.
- `guard_action` removed unused `_tiered_guards` class attribute storage.

### Removed
- Dead configuration attributes: `payment_processor`, `trial_period_days`, `downgrade_policy`, `event_handlers`, `message_builder` (declared but never read anywhere).
- `warning_thresholds` from plan DSL (accepted but never read).
- `Tiered::Validators::CountValidator`, `FeatureValidator`, `HistoryValidator` — no callers exist; quota enforcement is handled by `QuotaLimited` and `QuotaEnforcer`.

### Renamed
- Gem renamed from `plan_pay` to `tiered`. Module: `Tiered`. Tables: `tiered_assignments`, `tiered_quota_states`, `tiered_usages`. Generator: `rails generate tiered:install`.

## [0.1.0] - 2026-03-04

### Added
- Plan definition DSL (`Tiered.configure { |c| c.plan(:free) { ... } }`) supporting persistent and per-period quotas, feature restrictions, and after-quota policies (`:block_usage`, `:grace_then_block`, `:just_warn`).
- `Tiered::Concerns::HasPlan` — mixin for owner models (User, Team) providing `current_plan`, `within_quota?`, `quota_remaining`, `quota_percent_used`, `assign_plan!`, `remove_plan!`, `free_tier?`, `paid_tier?`, `quota_severity`, `quota_message`.
- `Tiered::Concerns::QuotaLimited` — mixin for resource models with `quota_limited_by` macro that adds a `before_validation` quota check on create.
- `Tiered::Rails::ActionGuards` — controller concern with `guard_action :create, quota: :projects` that installs a `before_action` enforcing quota policy.
- `Tiered::Rails::ViewHelpers` — auto-mixed into ActionView via Railtie; provides `tiered_quota_alert`, `tiered_quota_meter`, `quota_remaining`, `quota_percent_used`, `quota_severity`, `quota_message`, `plan_allows?`.
- `Tiered::Services::ConsumptionTracker.track` for incrementing per-period usage counters.
- `Tiered::Services::QuotaChecker.check` returning a `Result` value object (`within_quota?`, `remaining`, `percent_used`, `unlimited?`).
- `Tiered::Services::QuotaEnforcer.enforce` applying the plan's after-quota policy.
- `Tiered::Services::PlanResolver` for resolving and assigning plans to owners.
- `rails generate tiered:install` — copies initializer template and three migrations (`tiered_assignments`, `tiered_quota_states`, `tiered_usages`).
- MIT license. Extracted from RumiPay.
