# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-XX

### Added
- Initial release of PlanPay gem
- Configuration DSL for defining plans with quotas and restrictions
- Plan registry and resolution system (manual → default)
- Three core database tables: assignments, quota_states, usages
- Rails generator (`plan_pay:install`) for easy setup
- PlanResolver service for resolving user plans
- QuotaChecker service for checking persistent and per-period quotas
- PeriodCalculator service for billing period calculations
- QuotaEnforcer service with three policies: `:block_usage`, `:grace_then_block`, `:just_warn`
- ConsumptionTracker service for tracking per-period usage
- HasPlan concern for User/Organization models
- QuotaLimited concern for resource models
- ActionGuards mixin for controller quota enforcement
- ViewHelpers for quota meters, alerts, and status displays
- ActiveModel validators: CountValidator, FeatureValidator, HistoryValidator
- Comprehensive error handling with custom error classes

### Requirements
- Ruby >= 4.0.0
- Rails >= 8.0

