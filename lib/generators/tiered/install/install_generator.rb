# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module Tiered
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ::ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Installs Tiered and generates the necessary migrations and initializer'

      class_option :uuid, type: :boolean, default: nil, hide: true,
                          desc: 'Use UUID primary keys (auto-detected from app config if not set)'

      def create_migrations
        migration_template 'migrations/create_tiered_assignments.rb',
                           'db/migrate/create_tiered_assignments.rb'
        migration_template 'migrations/create_tiered_quota_states.rb',
                           'db/migrate/create_tiered_quota_states.rb'
        migration_template 'migrations/create_tiered_usages.rb',
                           'db/migrate/create_tiered_usages.rb'
      end

      def create_initializer
        template 'tiered.rb', 'config/initializers/tiered.rb'
      end

      private

      def uuid?
        return options[:uuid] unless options[:uuid].nil?

        detect_uuid_from_app?
      end

      def detect_uuid_from_app?
        return false unless defined?(::Rails) && ::Rails.application

        ar_config = ::Rails.application.config.generators.options[:active_record] || {}
        ar_config[:primary_key_type] == :uuid
      rescue StandardError
        false
      end
    end
  end
end
