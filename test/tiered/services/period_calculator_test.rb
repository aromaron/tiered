# frozen_string_literal: true

require 'test_helper'

module Tiered
  module Services
    class PeriodCalculatorTest < Minitest::Test
      def test_calculate_calendar_month
        time = Time.utc(2026, 1, 15, 12, 0, 0)
        period = PeriodCalculator.calculate(:calendar_month, time)

        assert_equal Time.utc(2026, 1, 1, 0, 0, 0), period[:start]
        # end_of_month may return different precision, so just check it's at end of month
        assert_equal 2026, period[:end].year
        assert_equal 1, period[:end].month
        assert_equal 31, period[:end].day
      end

      def test_calculate_calendar_week
        time = Time.utc(2026, 1, 15, 12, 0, 0) # Wednesday
        period = PeriodCalculator.calculate(:calendar_week, time)

        assert_predicate period[:start], :monday?
        assert_predicate period[:end], :sunday?
      end

      def test_calculate_calendar_day
        time = Time.utc(2026, 1, 15, 12, 30, 0)
        period = PeriodCalculator.calculate(:calendar_day, time)

        assert_equal time.beginning_of_day, period[:start]
        assert_equal time.end_of_day, period[:end]
      end

      def test_current_period
        period = PeriodCalculator.current_period

        refute_nil period[:start]
        refute_nil period[:end]
      end
    end
  end
end
