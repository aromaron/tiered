# frozen_string_literal: true

require_relative 'lib/plan_pay/version'

Gem::Specification.new do |spec|
  spec.name = 'plan_pay'
  spec.version = PlanPay::VERSION
  spec.authors = ['Nora Alvarado']
  spec.email = ['aromaron@users.noreply.github.com']

  spec.summary = 'Define and enforce pricing plan limits in Rails applications'
  spec.description = 'PlanPay helps you define pricing tiers and enforce usage limits based on subscription plans. Extracted from RumiPay.'
  spec.homepage = 'https://github.com/aromaron/plan_pay'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  # Prevent accidental pushes to RubyGems (private gem)
  # spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/aromaron/plan_pay'
  spec.metadata['changelog_uri'] = 'https://github.com/aromaron/plan_pay/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
