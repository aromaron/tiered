# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module PlanPay
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Installs PlanPay and generates the necessary migrations and initializer'

      def create_migrations
        migration_template 'migrations/create_plan_pay_assignments.rb',
                           "db/migrate/#{migration_file_name_prefix}_create_plan_pay_assignments.rb"
        migration_template 'migrations/create_plan_pay_quota_states.rb',
                           "db/migrate/#{migration_file_name_prefix}_create_plan_pay_quota_states.rb"
        migration_template 'migrations/create_plan_pay_usages.rb',
                           "db/migrate/#{migration_file_name_prefix}_create_plan_pay_usages.rb"
      end

      def create_initializer
        template 'plan_pay.rb', 'config/initializers/plan_pay.rb'
      end

      private

      def migration_file_name_prefix
        Time.now.utc.strftime('%Y%m%d%H%M%S')
      end
    end
  end
end
