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

  # === Validate ===

  test "validate calls ValidationService" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @builder.build
    assert result.success?

    validation_result = @builder.validate

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
