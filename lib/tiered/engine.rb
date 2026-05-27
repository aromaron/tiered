# frozen_string_literal: true

module Tiered
  if defined?(Rails::Engine)
    class Engine < Rails::Engine
      generators do
        require_relative '../generators/tiered/install/install_generator'
      end

      initializer 'tiered.view_helpers' do
        ActiveSupport.on_load(:action_view) do
          include Tiered::Rails::ViewHelpers
        end
      end
    end
  end
end
