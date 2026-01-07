# frozen_string_literal: true

module PlanPay
  if defined?(Rails::Railtie)
    class Railtie < Rails::Railtie
      generators do
        require_relative '../generators/plan_pay/install/install_generator'
      end

      initializer 'plan_pay.view_helpers' do
        ActiveSupport.on_load(:action_view) do
          include PlanPay::Rails::ViewHelpers
        end
      end
    end
  end
end
