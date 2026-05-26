# frozen_string_literal: true

require 'test_helper'
require 'rails/generators/test_case'
require 'generators/tiered/install/install_generator'

class Tiered::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests Tiered::Generators::InstallGenerator
  destination File.expand_path('../../../tmp/generator_output', __dir__)

  setup :prepare_destination

  def test_creates_initializer
    run_generator
    assert_file 'config/initializers/tiered.rb' do |content|
      assert_match(/Tiered\.configure/, content)
    end
  end

  def test_creates_assignments_migration
    run_generator
    assert_migration 'db/migrate/create_tiered_assignments.rb' do |content|
      assert_match(/create_table :tiered_assignments/, content)
    end
  end

  def test_creates_quota_states_migration
    run_generator
    assert_migration 'db/migrate/create_tiered_quota_states.rb' do |content|
      assert_match(/create_table :tiered_quota_states/, content)
    end
  end

  def test_creates_usages_migration
    run_generator
    assert_migration 'db/migrate/create_tiered_usages.rb' do |content|
      assert_match(/create_table :tiered_usages/, content)
    end
  end
end
