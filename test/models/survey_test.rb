# frozen_string_literal: true

require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @survey = Survey.new(organization: @organization, year: 2025)
  end

  test "initializes with organization and year" do
    assert_equal @organization, @survey.organization
    assert_equal 2025, @survey.year
  end

  test "questionnaire returns gem questionnaire for year" do
    questionnaire = @survey.send(:questionnaire)

    assert_instance_of AmsfSurvey::Questionnaire, questionnaire
    assert_equal 2025, questionnaire.year
    assert_equal :real_estate, questionnaire.industry
  end

  test "build_submission creates gem submission with entity info" do
    submission = @survey.send(:build_submission)

    assert_instance_of AmsfSurvey::Submission, submission
    assert_equal @organization.rci_number, submission.entity_id
    assert_equal Date.new(2025, 12, 31), submission.period
  end

  test "to_xbrl generates valid XML" do
    xbrl = @survey.to_xbrl

    assert_includes xbrl, '<?xml version="1.0"'
    assert_includes xbrl, "xbrli:xbrl"
    assert_includes xbrl, @organization.rci_number
  end

  test "valid? returns validation status" do
    # With no field implementations, submission has missing required fields
    assert_respond_to @survey, :valid?
    assert_equal false, @survey.valid?  # Expected to fail initially
  end

  test "missing_fields returns array of missing field IDs" do
    missing = @survey.missing_fields

    assert_respond_to missing, :each
    assert missing.any?, "Expected missing fields for incomplete submission"
  end

  test "completion_percentage returns percentage complete" do
    percentage = @survey.completion_percentage

    assert_kind_of Numeric, percentage
    assert percentage >= 0 && percentage <= 100
  end

  test "field_label returns label from questionnaire" do
    label = @survey.field_label("aactive")

    assert_not_nil label
    assert_includes label, "mandataire professionnel"
  end

  test "field_value returns calculated value for field" do
    value = @survey.field_value("a1101")

    assert_not_nil value
    assert_equal @organization.clients.count, value
  end

  # === CustomerRisk Field Tests ===

  test "a1101 (total_clients) is a private method" do
    assert_includes @survey.private_methods, :a1101
    assert_raises(NoMethodError) { @survey.a1101 }
  end

  test "a1101 (total_clients) returns count of clients for organization" do
    # Organization :one has multiple clients in fixtures
    expected_count = @organization.clients.count
    actual_count = @survey.send(:a1101)

    assert_equal expected_count, actual_count
    assert actual_count > 0, "Expected organization to have clients in fixtures"
  end

  # === Tabs Structure Tests ===

  test "tabs returns array of 5 tabs with field IDs from modules" do
    tabs = @survey.tabs

    assert_equal 5, tabs.size
    assert_equal %i[customer_risk products_services_risk distribution_risk controls signatories], tabs.map { |t| t[:key] }
  end

  test "tabs include all field methods from corresponding modules" do
    tabs = @survey.tabs

    # CustomerRisk should include a1101 (total_clients)
    customer_risk_tab = tabs.find { |t| t[:key] == :customer_risk }
    assert_includes customer_risk_tab[:fields], "a1101"

    # Controls should include ac1201 (AML policy)
    controls_tab = tabs.find { |t| t[:key] == :controls }
    assert_includes controls_tab[:fields], "ac1201"
  end

  test "tabs exclude helper methods" do
    tabs = @survey.tabs
    all_fields = tabs.flat_map { |t| t[:fields] }

    # Helper methods should not appear in any tab
    Survey::HELPER_METHODS.each do |helper|
      assert_not_includes all_fields, helper, "Helper method #{helper} should not be in tabs"
    end
  end

  test "tabs fields are sorted by gem display order" do
    tabs = @survey.tabs
    customer_risk_tab = tabs.find { |t| t[:key] == :customer_risk }
    fields = customer_risk_tab[:fields]

    # aactive should come before a1101 (order 1 vs order 4)
    assert fields.index("aactive") < fields.index("a1101"),
      "Fields should be sorted by gem display order"
  end
end
