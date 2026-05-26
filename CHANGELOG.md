# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
