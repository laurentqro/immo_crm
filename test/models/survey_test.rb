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

  test "a1204s1 returns BO nationality breakdown as Hash for dimensional XBRL" do
    result = @survey.send(:a1204s1)

    # Should be a Hash with ISO country codes as keys and percentages as values
    assert_kind_of Hash, result
    assert result.any?, "Expected at least one nationality entry"

    # Keys should be ISO country codes (2-letter strings)
    result.each_key do |code|
      assert_match(/\A[A-Z]{2}\z/, code, "Expected ISO country code, got '#{code}'")
    end

    # Values should be numeric percentages
    result.each_value do |percentage|
      assert_kind_of Numeric, percentage
      assert percentage >= 0 && percentage <= 100, "Percentage #{percentage} out of range"
    end

    # Percentages should sum to approximately 100
    total = result.values.sum
    assert_in_delta 100, total, 1, "Percentages should sum to ~100, got #{total}"
  end

  test "a1204s1 uses ISO country codes as keys" do
    result = @survey.send(:a1204s1)

    # Should use ISO codes like "FR", "MC" as keys
    assert result.keys.all? { |k| k.match?(/\A[A-Z]{2}\z/) }, "Expected all keys to be ISO codes"
  end

  test "a1204s1 excludes beneficial owners without nationality" do
    result = @survey.send(:a1204s1)

    # minimal_owner fixture has no nationality - should be excluded
    # Verify no nil keys or zero values (empty nationalities filtered out)
    refute result.key?(nil), "Should not include nil key"
    refute result.key?(""), "Should not include empty string key"
    assert result.values.all? { |v| v > 0 }, "All percentages should be > 0"
  end

  # === ProductsServicesRisk Field Tests ===

  test "air233 returns Hash grouped by property country" do
    result = @survey.send(:air233)

    # Should be a Hash with ISO country codes as keys and counts as values
    assert_kind_of Hash, result
  end

  test "air233 uses ISO country codes as keys" do
    result = @survey.send(:air233)

    # All keys should be 2-letter ISO country codes
    result.each_key do |code|
      assert_match(/\A[A-Z]{2}\z/, code, "Expected ISO country code, got '#{code}'")
    end
  end

  test "air233 counts only transactions with agency_role" do
    # Get expected count from fixture data
    expected_count = @organization.transactions.kept
      .where(transaction_date: Date.new(2025, 1, 1)..Date.new(2025, 12, 31))
      .where.not(agency_role: [nil, ""])
      .where.not(property_country: [nil, ""])
      .count

    result = @survey.send(:air233)
    actual_count = result.values.sum

    assert_equal expected_count, actual_count
  end

  test "air233 excludes transactions without property_country" do
    result = @survey.send(:air233)

    refute result.key?(nil), "Should not include nil key"
    refute result.key?(""), "Should not include empty string key"
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

  # === DistributionRisk Introducer Field Tests ===

  # Use compliance_test_org which has introducer fixtures:
  # - introduced_from_france (IT nationality, FR introducer, this year)
  # - introduced_from_switzerland (FR nationality, CH introducer, this year)
  # - introduced_from_uk_last_year (GB nationality, GB introducer, last year)
  # - introduced_from_france_last_year (MC nationality, FR introducer, last year)
  # - not_introduced (MC nationality, not introduced)

  test "a3201 returns Oui when introduced clients exist" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3201)

    assert_equal "Oui", result
  end

  test "a3201 returns Non when no introduced clients exist" do
    org = organizations(:two) # organization with no introduced clients
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3201)

    assert_equal "Non", result
  end

  test "a3202 returns Hash grouped by client nationality for all introduced clients" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3202)

    assert_kind_of Hash, result
    # Should include all 4 introduced clients:
    # IT (1), FR (1), GB (1), MC (1)
    assert_equal 4, result.values.sum
    assert result.key?("IT")
    assert result.key?("FR")
    assert result.key?("GB")
    assert result.key?("MC")
  end

  test "a3204 returns Hash grouped by client nationality for this year only" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3204)

    assert_kind_of Hash, result
    # Should only include 2 clients introduced this year:
    # introduced_from_france (IT), introduced_from_switzerland (FR)
    assert_equal 2, result.values.sum
    assert result.key?("IT")
    assert result.key?("FR")
    refute result.key?("GB"), "Should not include GB (introduced last year)"
  end

  test "a3203 returns Hash grouped by introducer country for all introduced clients" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3203)

    assert_kind_of Hash, result
    # Should group by introducer_country:
    # FR (2 clients - introduced_from_france + introduced_from_france_last_year)
    # CH (1), GB (1)
    assert_equal 4, result.values.sum
    assert_equal 2, result["FR"]
    assert_equal 1, result["CH"]
    assert_equal 1, result["GB"]
  end

  test "a3205 returns Hash grouped by introducer country for this year only" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3205)

    assert_kind_of Hash, result
    # Should only include 2 clients introduced this year:
    # FR (1 - introduced_from_france), CH (1 - introduced_from_switzerland)
    assert_equal 2, result.values.sum
    assert_equal 1, result["FR"]
    assert_equal 1, result["CH"]
    refute result.key?("GB"), "Should not include GB (introduced last year)"
  end

  test "a3501b returns Oui (we track client nationality)" do
    result = @survey.send(:a3501b)

    assert_equal "Oui", result
  end

  test "a3501c returns Oui (we track introducer country)" do
    result = @survey.send(:a3501c)

    assert_equal "Oui", result
  end

end
