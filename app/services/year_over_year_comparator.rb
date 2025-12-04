# frozen_string_literal: true

# YearOverYearComparator compares submission values between consecutive years.
#
# Used to detect significant changes (>25% deviation) that may require
# additional review or justification per FR-019.
#
# Example:
#   comparator = YearOverYearComparator.new(submission_2024)
#   comparator.previous_submission  # => submission_2023
#   comparator.comparison_for("a1101")  # => {current_value: 120, previous_value: 100, change_percent: 20.0}
#   comparator.significant_changes  # => [{element_name: "a2101B", ...}]
#
class YearOverYearComparator
  SIGNIFICANCE_THRESHOLD = 25.0

  attr_reader :submission, :organization, :year

  def initialize(submission)
    @submission = submission
    @organization = submission.organization
    @year = submission.year
  end

  # Find the previous year's submission for the same organization
  def previous_submission
    @previous_submission ||= organization.submissions
      .where(year: year - 1)
      .first
  end

  # Check if this is the first submission (no prior year data)
  def first_submission?
    previous_submission.nil?
  end

  # Compare a specific element between current and previous years
  # Returns hash with :current_value, :previous_value, :change_percent, :significant
  def comparison_for(element_name)
    current_sv = submission.submission_values.find_by(element_name: element_name)
    previous_sv = previous_submission&.submission_values&.find_by(element_name: element_name)

    current_value = current_sv&.value
    previous_value = previous_sv&.value

    change_percent = calculate_change_percent(current_value, previous_value)

    {
      element_name: element_name,
      current_value: current_value,
      previous_value: previous_value,
      change_percent: change_percent,
      significant: significant?(change_percent)
    }
  end

  # Return all elements with significant changes (>25% deviation)
  def significant_changes
    return [] if first_submission?

    # Get all current submission values
    submission.submission_values.map do |sv|
      comparison = comparison_for(sv.element_name)
      comparison if comparison[:significant]
    end.compact
  end

  # Check if a change percentage is significant (>25% in either direction)
  def significant?(change_percent)
    return false if change_percent.nil?

    change_percent.abs > SIGNIFICANCE_THRESHOLD
  end

  private

  # Calculate percentage change between two values
  # Returns nil if calculation isn't possible (zero/nil previous value)
  def calculate_change_percent(current_value, previous_value)
    return nil if current_value.nil? || previous_value.nil?

    current_num = BigDecimal(current_value.to_s) rescue nil
    previous_num = BigDecimal(previous_value.to_s) rescue nil

    return nil if current_num.nil? || previous_num.nil?
    return nil if previous_num.zero?

    ((current_num - previous_num) / previous_num * 100).to_f.round(2)
  end
end
