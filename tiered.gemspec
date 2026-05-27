# frozen_string_literal: true

require_relative 'lib/tiered/version'

Gem::Specification.new do |spec|
  spec.name = 'tiered'
  spec.version = Tiered::VERSION
  spec.authors = ['Nora Alvarado']
  spec.email = ['aromaron@users.noreply.github.com']

  spec.summary = 'Define and enforce pricing plan limits in Rails applications'
  spec.description = 'Tiered helps you define pricing tiers and enforce usage limits based on subscription plans. Extracted from RumiPay.'
  spec.homepage = 'https://github.com/aromaron/tiered'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/aromaron/tiered'
  spec.metadata['changelog_uri'] = 'https://github.com/aromaron/tiered/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 7.0'
  spec.add_dependency 'activerecord', '>= 7.0'
  spec.add_dependency 'activemodel', '>= 7.0'
  spec.add_dependency 'railties', '>= 7.0'

  spec.add_development_dependency 'rails', '>= 7.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'standard'
  spec.add_development_dependency 'simplecov'
end
