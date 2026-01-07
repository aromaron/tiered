# frozen_string_literal: true

require_relative "lib/plan_pay/version"

Gem::Specification.new do |spec|
  spec.name = "plan_pay"
  spec.version = PlanPay::VERSION
  spec.authors = ["Nora Alvarado"]
  spec.email = ["nora.alvarado@hey.com"]

  spec.summary = "Plan and pay for Rails apps"
  spec.description = "A comprehensive Rails gem for billing integration, subscription management, and feature gating"
  spec.homepage = "https://github.com/aromaron/plan_pay"
  spec.required_ruby_version = ">= 4.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aromaron/plan_pay"
  spec.metadata["changelog_uri"] = "https://github.com/aromaron/plan_pay/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "activerecord", ">= 7.1"
  spec.add_dependency "activesupport", ">= 7.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
