# frozen_string_literal: true

require "test_helper"

class YearOverYearComparatorTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    # Create submissions for two consecutive years (using future years to avoid fixture conflicts)
    @submission_prev = Submission.create!(
      organization: @organization,
      year: 2050
    )
    @submission_curr = Submission.create!(
      organization: @organization,
      year: 2051
    )

    # Add some values to the previous year submission
    @submission_prev.submission_values.create!(
      element_name: "a1101",
      value: "100",
      source: "calculated"
    )
    @submission_prev.submission_values.create!(
      element_name: "a2101B",
      value: "50",
      source: "calculated"
    )

    # Add values to current submission
    @submission_curr.submission_values.create!(
      element_name: "a1101",
      value: "120", # 20% increase
      source: "calculated"
    )
    @submission_curr.submission_values.create!(
      element_name: "a2101B",
      value: "75", # 50% increase (significant)
      source: "calculated"
    )

    @comparator = YearOverYearComparator.new(@submission_curr)
  end

  # === Initialization ===

  test "initializes with current submission" do
    comparator = YearOverYearComparator.new(@submission_curr)
    assert_not_nil comparator
  end

  test "finds previous year submission" do
    assert_equal @submission_prev, @comparator.previous_submission
  end

  test "returns nil for previous submission when none exists" do
    # Create a submission for a year with no prior submission (using far future year)
    early_submission = Submission.create!(
      organization: @organization,
      year: 2040
    )
    comparator = YearOverYearComparator.new(early_submission)
    assert_nil comparator.previous_submission
  end

  # === Comparison Methods ===

  test "comparison_for returns hash with current and previous values" do
    result = @comparator.comparison_for("a1101")

    assert_kind_of Hash, result
    assert result.key?(:current_value)
    assert result.key?(:previous_value)
    assert result.key?(:change_percent)
  end

  test "comparison_for calculates correct percentage change" do
    result = @comparator.comparison_for("a1101")

    # 100 -> 120 = 20% increase
    assert_equal 120, result[:current_value].to_i
    assert_equal 100, result[:previous_value].to_i
    assert_in_delta 20.0, result[:change_percent], 0.01
  end

  test "comparison_for handles significant increase" do
    result = @comparator.comparison_for("a2101B")

    # 50 -> 75 = 50% increase (significant)
    assert_in_delta 50.0, result[:change_percent], 0.01
    assert result[:significant], "Expected 50% change to be significant"
  end

  test "comparison_for returns nil previous when no prior submission" do
    early_submission = Submission.create!(
      organization: @organization,
      year: 2041
    )
    early_submission.submission_values.create!(
      element_name: "a1101",
      value: "100",
      source: "calculated"
    )

    comparator = YearOverYearComparator.new(early_submission)
    result = comparator.comparison_for("a1101")

    assert_equal 100, result[:current_value].to_i
    assert_nil result[:previous_value]
    assert_nil result[:change_percent]
  end

  test "comparison_for handles element not in current submission" do
    result = @comparator.comparison_for("nonexistent_element")

    assert_nil result[:current_value]
    assert_nil result[:previous_value]
    assert_nil result[:change_percent]
  end

  # === Significant Changes Detection ===

  test "significant_changes returns elements with >25% change" do
    changes = @comparator.significant_changes

    assert_kind_of Array, changes
    # a2101B has 50% change, should be included
    element_names = changes.map { |c| c[:element_name] }
    assert_includes element_names, "a2101B"
    # a1101 has 20% change, should NOT be included
    assert_not_includes element_names, "a1101"
  end

  test "significant_changes returns empty array when no significant changes" do
    # Update a2101B to have non-significant change
    @submission_curr.submission_values.find_by(element_name: "a2101B")
                    .update!(value: "55") # 10% increase from 50

    changes = @comparator.significant_changes
    element_names = changes.map { |c| c[:element_name] }
    assert_not_includes element_names, "a2101B"
  end

  test "significant_changes includes both increases and decreases" do
    # Add a value that decreased significantly
    @submission_prev.submission_values.create!(
      element_name: "a3101",
      value: "100",
      source: "calculated"
    )
    @submission_curr.submission_values.create!(
      element_name: "a3101",
      value: "50", # 50% decrease (significant)
      source: "calculated"
    )

    changes = @comparator.significant_changes
    element_names = changes.map { |c| c[:element_name] }
    assert_includes element_names, "a3101"
  end

  # === Threshold Configuration ===

  test "significant? returns true for changes above 25% threshold" do
    assert @comparator.significant?(30.0)
    assert @comparator.significant?(-30.0) # Decrease
    assert @comparator.significant?(25.01)
  end

  test "significant? returns false for changes at or below 25% threshold" do
    assert_not @comparator.significant?(25.0)
    assert_not @comparator.significant?(-25.0)
    assert_not @comparator.significant?(20.0)
    assert_not @comparator.significant?(0.0)
  end

  test "significant? handles nil gracefully" do
    assert_not @comparator.significant?(nil)
  end

  # === Edge Cases ===

  test "handles zero previous value" do
    @submission_prev.submission_values.create!(
      element_name: "a_zero_test",
      value: "0",
      source: "calculated"
    )
    @submission_curr.submission_values.create!(
      element_name: "a_zero_test",
      value: "100",
      source: "calculated"
    )

    result = @comparator.comparison_for("a_zero_test")
    # Division by zero should return nil or infinity indicator
    assert_nil result[:change_percent]
  end

  test "handles string values with proper conversion" do
    result = @comparator.comparison_for("a1101")
    assert_equal 120, result[:current_value].to_i
    assert_equal 100, result[:previous_value].to_i
  end

  test "first_submission? returns true when no previous year" do
    early_submission = Submission.create!(
      organization: @organization,
      year: 2042
    )
    comparator = YearOverYearComparator.new(early_submission)
    assert comparator.first_submission?
  end

  test "first_submission? returns false when previous year exists" do
    assert_not @comparator.first_submission?
  end
end
