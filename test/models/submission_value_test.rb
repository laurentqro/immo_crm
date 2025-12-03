# frozen_string_literal: true

require "test_helper"

class SubmissionValueTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
    @submission = submissions(:draft_submission)
  end

  # === Basic Validations ===

  test "valid submission_value with required attributes" do
    value = SubmissionValue.new(
      submission: @submission,
      element_name: "test_element_new",
      source: "calculated"
    )
    assert value.valid?
  end

  test "requires submission" do
    value = SubmissionValue.new(
      element_name: "a1101",
      source: "calculated"
    )
    assert_not value.valid?
    assert_includes value.errors[:submission], "must exist"
  end

  test "requires element_name" do
    value = SubmissionValue.new(
      submission: @submission,
      source: "calculated"
    )
    assert_not value.valid?
    assert_includes value.errors[:element_name], "can't be blank"
  end

  test "requires source" do
    value = SubmissionValue.new(
      submission: @submission,
      element_name: "a1101"
    )
    assert_not value.valid?
    assert_includes value.errors[:source], "can't be blank"
  end

  test "source must be valid" do
    value = SubmissionValue.new(
      submission: @submission,
      element_name: "a1101",
      source: "INVALID"
    )
    assert_not value.valid?
    assert_includes value.errors[:source], "is not included in the list"
  end

  test "accepts all valid sources" do
    %w[calculated from_settings manual].each do |source|
      value = SubmissionValue.new(
        submission: @submission,
        element_name: "test_#{source}",
        source: source
      )
      assert value.valid?, "Expected source '#{source}' to be valid"
    end
  end

  test "element_name must be unique per submission" do
    # Create first value with unique element name
    SubmissionValue.create!(
      submission: @submission,
      element_name: "test_unique_check",
      source: "calculated",
      value: "42"
    )

    # Duplicate should fail
    duplicate = SubmissionValue.new(
      submission: @submission,
      element_name: "test_unique_check",
      source: "calculated"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:element_name], "has already been taken"
  end

  test "same element_name allowed for different submissions" do
    other_submission = submissions(:another_submission)

    # Create value for first submission with unique element name
    SubmissionValue.create!(
      submission: @submission,
      element_name: "test_cross_sub",
      source: "calculated",
      value: "42"
    )

    # Same element for different submission should work
    value = SubmissionValue.new(
      submission: other_submission,
      element_name: "test_cross_sub",
      source: "calculated"
    )
    assert value.valid?
  end

  # === Default Values ===

  test "overridden defaults to false" do
    value = SubmissionValue.new(
      submission: @submission,
      element_name: "test_override_default",
      source: "calculated"
    )
    assert_equal false, value.overridden
  end

  test "value can be nil" do
    value = SubmissionValue.new(
      submission: @submission,
      element_name: "test_nil_value",
      source: "calculated",
      value: nil
    )
    assert value.valid?
  end

  # === Associations ===

  test "belongs to submission" do
    value = submission_values(:client_count)
    assert_equal @submission, value.submission
  end

  # === Scopes ===

  test "calculated scope returns only calculated values" do
    calculated = submission_values(:client_count)
    from_settings = submission_values(:policy_setting)

    results = SubmissionValue.calculated
    assert_includes results, calculated
    assert_not_includes results, from_settings
  end

  test "from_settings scope returns only from_settings values" do
    calculated = submission_values(:client_count)
    from_settings = submission_values(:policy_setting)

    results = SubmissionValue.from_settings
    assert_includes results, from_settings
    assert_not_includes results, calculated
  end

  test "manual scope returns only manual values" do
    manual = submission_values(:manual_answer)
    calculated = submission_values(:client_count)

    results = SubmissionValue.manual
    assert_includes results, manual
    assert_not_includes results, calculated
  end

  test "overridden scope returns only overridden values" do
    overridden = submission_values(:overridden_value)
    normal = submission_values(:client_count)

    results = SubmissionValue.overridden_values
    assert_includes results, overridden
    assert_not_includes results, normal
  end

  test "confirmed scope returns values with confirmed_at set" do
    confirmed = submission_values(:confirmed_value)
    unconfirmed = submission_values(:client_count)

    results = SubmissionValue.confirmed
    assert_includes results, confirmed
    assert_not_includes results, unconfirmed
  end

  test "unconfirmed scope returns values without confirmed_at" do
    confirmed = submission_values(:confirmed_value)
    unconfirmed = submission_values(:client_count)

    results = SubmissionValue.unconfirmed
    assert_includes results, unconfirmed
    assert_not_includes results, confirmed
  end

  # === Source Predicates ===

  test "calculated? returns true for calculated values" do
    value = SubmissionValue.new(source: "calculated")
    assert value.calculated?
    assert_not value.from_settings?
    assert_not value.manual?
  end

  test "from_settings? returns true for from_settings values" do
    value = SubmissionValue.new(source: "from_settings")
    assert value.from_settings?
    assert_not value.calculated?
    assert_not value.manual?
  end

  test "manual? returns true for manual values" do
    value = SubmissionValue.new(source: "manual")
    assert value.manual?
    assert_not value.calculated?
    assert_not value.from_settings?
  end

  # === Confirmation ===

  test "confirm! sets confirmed_at" do
    value = SubmissionValue.create!(
      submission: @submission,
      element_name: "test_confirm",
      source: "calculated",
      value: "42"
    )
    assert_nil value.confirmed_at

    value.confirm!
    assert_not_nil value.confirmed_at
  end

  test "confirmed? returns true when confirmed_at is set" do
    value = SubmissionValue.new(confirmed_at: Time.current)
    assert value.confirmed?
  end

  test "confirmed? returns false when confirmed_at is nil" do
    value = SubmissionValue.new(confirmed_at: nil)
    assert_not value.confirmed?
  end

  # === Override Tracking ===

  test "mark_overridden! sets overridden flag" do
    value = SubmissionValue.create!(
      submission: @submission,
      element_name: "test_override",
      source: "calculated",
      value: "42"
    )
    assert_not value.overridden

    value.mark_overridden!
    assert value.overridden
  end

  test "updating value from calculated source marks as overridden" do
    value = SubmissionValue.create!(
      submission: @submission,
      element_name: "test_auto_override",
      source: "calculated",
      value: "42"
    )

    value.update_value!("50")
    assert value.overridden
    assert_equal "50", value.value
  end

  test "updating value from manual source does not mark as overridden" do
    value = SubmissionValue.create!(
      submission: @submission,
      element_name: "test_manual_update",
      source: "manual",
      value: "answer1"
    )

    value.update_value!("answer2")
    assert_not value.overridden
    assert_equal "answer2", value.value
  end

  # === Type Casting Helpers ===

  test "to_integer returns value as integer" do
    value = SubmissionValue.new(value: "42")
    assert_equal 42, value.to_integer
  end

  test "to_integer returns 0 for nil value" do
    value = SubmissionValue.new(value: nil)
    assert_equal 0, value.to_integer
  end

  test "to_decimal returns value as BigDecimal" do
    value = SubmissionValue.new(value: "1234.56")
    assert_equal BigDecimal("1234.56"), value.to_decimal
  end

  test "to_decimal returns 0 for nil value" do
    value = SubmissionValue.new(value: nil)
    assert_equal BigDecimal("0"), value.to_decimal
  end

  test "to_boolean returns true for truthy values" do
    %w[true 1 yes].each do |val|
      value = SubmissionValue.new(value: val)
      assert value.to_boolean, "Expected '#{val}' to be truthy"
    end
  end

  test "to_boolean returns false for falsy values" do
    [nil, "", "false", "0", "no"].each do |val|
      value = SubmissionValue.new(value: val)
      assert_not value.to_boolean, "Expected '#{val}' to be falsy"
    end
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert SubmissionValue.include?(AmsfConstants)
  end
end
