# frozen_string_literal: true

module PlanPay
  module Services
    class PeriodCalculator
      PERIOD_TYPES = {
        billing_cycle: :billing_cycle,
        calendar_month: :calendar_month,
        calendar_week: :calendar_week,
        calendar_day: :calendar_day
      }.freeze

      class << self
        def calculate(period_type, reference_time = Time.current)
          # Normalize common aliases
          period_type = normalize_period_type(period_type)

          case period_type
          when :billing_cycle
            calculate_billing_cycle(reference_time)
          when :calendar_month
            calculate_calendar_month(reference_time)
          when :calendar_week
            calculate_calendar_week(reference_time)
          when :calendar_day
            calculate_calendar_day(reference_time)
          else
            raise ArgumentError, "Unknown period type: #{period_type}"
          end
        end

        def normalize_period_type(period_type)
          case period_type
          when :month
            :calendar_month
          when :week
            :calendar_week
          when :day
            :calendar_day
          else
            period_type
          end
        end

        def current_period(period_type = nil)
          period_type ||= PlanPay.configuration.period_cycle
          calculate(period_type)
        end

        private

        def calculate_billing_cycle(reference_time)
          # For billing cycle, we use the first of the month as the start
          # This is a simplified version - can be enhanced with actual billing dates
          start_time = reference_time.beginning_of_month
          end_time = reference_time.end_of_month
          { start: start_time, end: end_time }
        end

        def calculate_calendar_month(reference_time)
          start_time = reference_time.beginning_of_month
          end_time = reference_time.end_of_month
          { start: start_time, end: end_time }
        end

        def calculate_calendar_week(reference_time)
          start_time = reference_time.beginning_of_week
          end_time = reference_time.end_of_week
          { start: start_time, end: end_time }
        end

        def calculate_calendar_day(reference_time)
          start_time = reference_time.beginning_of_day
          end_time = reference_time.end_of_day
          { start: start_time, end: end_time }
        end
      end
    end
  end
end
