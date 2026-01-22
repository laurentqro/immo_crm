# frozen_string_literal: true

require "test_helper"

class SubmissionBuilderTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    @builder = SubmissionBuilder.new(@organization, year: 2050)
  end

  # === Initialization ===

  test "initializes with organization and year" do
    builder = SubmissionBuilder.new(@organization, year: 2050)
    assert_not_nil builder
  end

  test "defaults year to current year" do
    builder = SubmissionBuilder.new(@organization)
    assert_equal Date.current.year, builder.year
  end

  # === Build Submission ===

  test "build creates new submission" do
    result = @builder.build

    assert result.success?
    assert_kind_of Submission, result.submission
    assert_equal @organization, result.submission.organization
    assert_equal 2050, result.submission.year
  end

  test "build populates calculated values" do
    result = @builder.build

    assert result.success?
    submission = result.submission
    assert submission.submission_values.exists?(element_name: "a1101")
  end

  test "build returns existing submission if already exists" do
    existing = Submission.create!(organization: @organization, year: 2051)

    builder = SubmissionBuilder.new(@organization, year: 2051)
    result = builder.build

    assert result.success?
    assert_equal existing.id, result.submission.id
  end

  # === Gem Submission (T008) ===

  test "gem_submission returns AmsfSurvey::Submission after build" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    gem_submission = builder.gem_submission

    assert_kind_of AmsfSurvey::Submission, gem_submission
    assert_equal :real_estate, gem_submission.industry
    assert_equal 2025, gem_submission.year
    assert_equal @organization.rci_number, gem_submission.entity_id
  end

  test "gem_submission raises NotBuiltError if build not called" do
    builder = SubmissionBuilder.new(@organization, year: 2025)

    assert_raises(SubmissionBuilder::NotBuiltError) do
      builder.gem_submission
    end
  end

  test "gem_submission contains values from AR submission" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    gem_submission = builder.gem_submission

    # Should have transferred values from CalculationEngine
    # a1101 is total client count - should exist if organization has clients
    assert gem_submission.data.keys.any?, "Gem submission should have some values"
  end

  # === Calculated Values Transfer (T037) ===

  test "calculated values from CalculationEngine populate gem submission correctly" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    # Get the calculated values directly from the submission
    submission = result.submission
    client_count_value = submission.submission_values.find_by(element_name: "a1101")

    # Verify the value was created by CalculationEngine
    assert_not_nil client_count_value, "a1101 should be calculated"
    assert_equal "calculated", client_count_value.source

    # Verify the value was transferred to gem submission
    gem_submission = builder.gem_submission
    gem_value = gem_submission[:a1101]

    # The gem should have the same value (type casting may differ)
    assert_equal client_count_value.value.to_s, gem_value.to_s,
                 "Calculated value should be transferred to gem submission"
  end

  test "boolean fields use Oui/Non format in gem submission" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    submission = result.submission
    gem_submission = builder.gem_submission

    # Find a boolean field like a11301 (PEP flag)
    boolean_value = submission.submission_values.find_by(element_name: "a11301")
    if boolean_value
      # Gem should have Oui/Non format
      gem_value = gem_submission[:a11301]
      assert %w[Oui Non].include?(gem_value.to_s) || gem_value.nil?,
             "Boolean field should use Oui/Non format, got: #{gem_value}"
    end
  end

  test "monetary fields maintain precision in gem submission" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    submission = result.submission
    gem_submission = builder.gem_submission

    # Find a monetary field like a2109B (total transaction value)
    monetary_value = submission.submission_values.find_by(element_name: "a2109B")
    if monetary_value && monetary_value.value.present?
      gem_value = gem_submission[:a2109B]
      # Both should represent the same monetary value
      original = BigDecimal(monetary_value.value.to_s)
      transferred = BigDecimal(gem_value.to_s) if gem_value.present?

      assert_equal original, transferred,
                   "Monetary field precision should be maintained"
    end
  end

  # === Generate XBRL ===

  test "generate_xbrl returns XBRL content" do
    result = @builder.build
    assert result.success?

    xbrl = @builder.generate_xbrl

    assert_kind_of String, xbrl
    assert_includes xbrl, "xbrl"
    assert_includes xbrl, "context"
  end

  test "generate_xbrl raises if build not called" do
    builder = SubmissionBuilder.new(@organization, year: 2060)

    assert_raises(SubmissionBuilder::NotBuiltError) do
      builder.generate_xbrl
    end
  end

  # === Validate (T009) ===

  test "validate returns AmsfSurvey::ValidationResult" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    validation_result = builder.validate

    assert_kind_of AmsfSurvey::ValidationResult, validation_result
    assert_respond_to validation_result, :valid?
    assert_respond_to validation_result, :errors
    assert_respond_to validation_result, :warnings
  end

  test "validate detects missing required fields" do
    builder = SubmissionBuilder.new(@organization, year: 2025)
    result = builder.build
    assert result.success?

    # Clear all submission values to simulate missing fields
    builder.submission.submission_values.destroy_all

    # Rebuild gem submission with empty values
    builder.send(:create_gem_submission)

    validation_result = builder.validate

    # Should have validation errors for missing required fields
    assert_not validation_result.valid?, "Validation should fail with missing required fields"
    assert validation_result.errors.any?, "Should have validation errors"
  end

  test "validate legacy calls ValidationService" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @builder.build
    assert result.success?

    validation_result = @builder.validate_with_arelle

    assert validation_result[:valid]
  end

  test "validate raises if build not called" do
    builder = SubmissionBuilder.new(@organization, year: 2061)

    assert_raises(SubmissionBuilder::NotBuiltError) do
      builder.validate
    end
  end

  # === Result Object ===

  test "result has success predicate" do
    result = @builder.build
    assert_respond_to result, :success?
  end

  test "result has submission" do
    result = @builder.build
    assert_respond_to result, :submission
  end

  test "result has errors" do
    result = @builder.build
    assert_respond_to result, :errors
  end

  # === Error Handling ===

  test "returns error result on invalid year" do
    builder = SubmissionBuilder.new(@organization, year: 1999)
    result = builder.build

    assert_not result.success?
    assert result.errors.any?
  end

  # === Full Workflow ===

  test "complete workflow builds validates and returns XBRL" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    builder = SubmissionBuilder.new(@organization, year: 2052)

    result = builder.build
    assert result.success?

    xbrl = builder.generate_xbrl
    assert_includes xbrl, "xbrl"

    validation = builder.validate
    assert validation[:valid]
  end
end
