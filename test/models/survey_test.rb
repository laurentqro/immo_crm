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
    questionnaire = @survey.questionnaire

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

  test "unanswered_questions returns array of Question objects" do
    unanswered = @survey.unanswered_questions

    assert_respond_to unanswered, :each
    assert unanswered.any?, "Expected unanswered questions for incomplete submission"
    assert_respond_to unanswered.first, :id
    assert_respond_to unanswered.first, :label
  end

  test "completion_percentage returns percentage complete" do
    percentage = @survey.completion_percentage

    assert_kind_of Numeric, percentage
    assert percentage >= 0 && percentage <= 100
  end

  test "question returns Question object from questionnaire" do
    question = @survey.question(:aactive)

    assert_not_nil question
    assert_respond_to question, :label
    assert_respond_to question, :instructions
    assert_includes question.label.downcase, "mandataire professionnel"
  end

  test "answer returns calculated value for question" do
    value = @survey.answer(:a1101)

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

  test "a1204s1 returns BO nationality breakdown as formatted percentages" do
    result = @survey.send(:a1204s1)

    # Should be a string with "Country: X%" format
    assert_kind_of String, result
    assert_match(/\w+: \d+%/, result, "Expected 'Country: X%' format")

    # Should contain comma-separated entries
    entries = result.split(", ")
    assert entries.length > 1, "Expected multiple nationalities"

    # Each entry should follow the format
    entries.each do |entry|
      assert_match(/\A[\w\s]+: \d+%\z/, entry, "Entry '#{entry}' doesn't match expected format")
    end

    # Percentages should sum to approximately 100
    percentages = result.scan(/(\d+)%/).flatten.map(&:to_i)
    total = percentages.sum
    assert_in_delta 100, total, 2, "Percentages should sum to ~100, got #{total}"
  end

  test "a1204s1 uses full country names not ISO codes" do
    result = @survey.send(:a1204s1)

    # Should contain full country names like "France" not "FR"
    assert_match(/France|Monaco|Italy/, result, "Expected full country names")
    refute_match(/\b[A-Z]{2}\b: \d+%/, result, "Should not contain ISO codes like 'FR: X%'")
  end

  test "a1204s1 excludes beneficial owners without nationality" do
    result = @survey.send(:a1204s1)

    # minimal_owner fixture has no nationality - should be excluded
    # Verify no empty or nil entries
    refute_match(/: 0%/, result, "Should not include 0% entries")
    refute_includes result, "nil"
    refute_includes result, ": %"
  end

  # === Sections/Subsections Structure Tests ===

  test "sections returns array of Section objects from questionnaire" do
    sections = @survey.sections

    assert sections.any?, "Expected at least one section"
    assert_respond_to sections.first, :title
    assert_respond_to sections.first, :number
    assert_respond_to sections.first, :subsections
  end

  test "sections contain subsections with questions" do
    section = @survey.sections.first
    subsection = section.subsections.first

    assert_not_nil subsection
    assert_respond_to subsection, :title
    assert_respond_to subsection, :number
    assert_respond_to subsection, :questions
    assert subsection.questions.any?, "Expected subsection to have questions"
  end

  test "questions have required attributes for display" do
    question = @survey.sections.first.subsections.first.questions.first

    assert_respond_to question, :id
    assert_respond_to question, :number
    assert_respond_to question, :label
    assert_respond_to question, :instructions
    assert_respond_to question, :type
  end

  test "questions are ordered by number within subsection" do
    subsection = @survey.sections.first.subsections.first
    questions = subsection.questions

    numbers = questions.map(&:number)
    assert_equal numbers, numbers.sort, "Questions should be ordered by number"
  end

  # === Arelle Validation Tests ===

  test "validate_with_arelle returns validation result when enabled" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: {valid: true, summary: {errors: 0}, messages: []}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    with_arelle_enabled do
      result = @survey.validate_with_arelle

      assert_instance_of ArelleClient::ValidationResult, result
      assert result.valid
    end
  end

  test "validate_with_arelle returns nil when disabled" do
    with_arelle_disabled do
      result = @survey.validate_with_arelle

      assert_nil result
    end
  end

  test "validate_with_arelle returns error result on validation failure" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          summary: {errors: 1},
          messages: [{severity: "error", code: "test", message: "Missing field"}]
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    with_arelle_enabled do
      result = @survey.validate_with_arelle

      assert_not result.valid
      assert_includes result.error_messages, "Missing field"
    end
  end

  test "validate_with_arelle raises ConnectionError when service unavailable" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_raise(Errno::ECONNREFUSED)

    with_arelle_enabled do
      assert_raises(ArelleClient::ConnectionError) do
        @survey.validate_with_arelle
      end
    end
  end

  private

  def with_arelle_enabled
    original = ENV["ARELLE_VALIDATION_ENABLED"]
    ENV["ARELLE_VALIDATION_ENABLED"] = "true"
    yield
  ensure
    ENV["ARELLE_VALIDATION_ENABLED"] = original
  end

  def with_arelle_disabled
    original = ENV["ARELLE_VALIDATION_ENABLED"]
    ENV["ARELLE_VALIDATION_ENABLED"] = "false"
    yield
  ensure
    ENV["ARELLE_VALIDATION_ENABLED"] = original
  end
end
