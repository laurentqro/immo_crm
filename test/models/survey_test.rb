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

  # === DistributionRisk Third-Party CDD Field Tests ===

  # Use compliance_test_org which has third-party CDD fixtures:
  # - local_third_party_cdd (FR nationality, LOCAL type)
  # - foreign_third_party_cdd (IT nationality, FOREIGN type, FR provider country)
  # - foreign_third_party_cdd_swiss (MC nationality, FOREIGN type, CH provider country)

  test "a3101 returns Oui when local third-party CDD clients exist" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3101)

    assert_equal "Oui", result
  end

  test "a3101 returns Non when no local third-party CDD clients exist" do
    org = organizations(:two) # organization with no third-party CDD clients
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3101)

    assert_equal "Non", result
  end

  test "a3103 returns Oui when foreign third-party CDD clients exist" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3103)

    assert_equal "Oui", result
  end

  test "a3103 returns Non when no foreign third-party CDD clients exist" do
    org = organizations(:two) # organization with no third-party CDD clients
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3103)

    assert_equal "Non", result
  end

  test "a3102 returns Hash grouped by client nationality for local CDD clients" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3102)

    assert_kind_of Hash, result
    # Should include only local_third_party_cdd (FR nationality)
    assert_equal 1, result.values.sum
    assert_equal 1, result["FR"]
  end

  test "a3102 returns empty Hash when no local CDD clients exist" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3102)

    assert_kind_of Hash, result
    assert result.empty?
  end

  test "a3104 returns Hash grouped by client nationality for foreign CDD clients" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3104)

    assert_kind_of Hash, result
    # Should include:
    # - foreign_third_party_cdd (IT nationality)
    # - foreign_third_party_cdd_swiss (MC nationality)
    assert_equal 2, result.values.sum
    assert_equal 1, result["IT"]
    assert_equal 1, result["MC"]
  end

  test "a3104 returns empty Hash when no foreign CDD clients exist" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3104)

    assert_kind_of Hash, result
    assert result.empty?
  end

  test "a3105 returns Hash grouped by third-party provider country" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3105)

    assert_kind_of Hash, result
    # Should include:
    # - foreign_third_party_cdd (FR provider country)
    # - foreign_third_party_cdd_swiss (CH provider country)
    assert_equal 2, result.values.sum
    assert_equal 1, result["FR"]
    assert_equal 1, result["CH"]
  end

  test "a3105 returns empty Hash when no foreign CDD clients exist" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a3105)

    assert_kind_of Hash, result
    assert result.empty?
  end

  test "ac1622f returns Oui when any third-party CDD is used" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:ac1622f)

    assert_equal "Oui", result
  end

  test "ac1622f returns Non when no third-party CDD is used" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:ac1622f)

    assert_equal "Non", result
  end

  # === HNWI/UHNWI Gate Field Tests ===

  test "a11201bcd returns Oui when HNWI beneficial owners exist" do
    # Org :one has hnwi_owner (10M) and uhnwi_owner (75M) fixtures
    result = @survey.send(:a11201bcd)

    assert_equal "Oui", result
  end

  test "a11201bcd returns Non when no HNWI beneficial owners exist" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a11201bcd)

    assert_equal "Non", result
  end

  test "a11201bcdu returns Oui when UHNWI beneficial owners exist" do
    # Org :one has uhnwi_owner (75M) fixture
    result = @survey.send(:a11201bcdu)

    assert_equal "Oui", result
  end

  test "a11201bcdu returns Non when no UHNWI beneficial owners exist" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a11201bcdu)

    assert_equal "Non", result
  end

  test "a11201bcd is consistent with a11206b — Oui iff breakdown has data" do
    result_gate = @survey.send(:a11201bcd)
    result_breakdown = @survey.send(:a11206b)

    if result_breakdown.any?
      assert_equal "Oui", result_gate, "Gate must be Oui when HNWI breakdown has data"
    else
      assert_equal "Non", result_gate, "Gate must be Non when HNWI breakdown is empty"
    end
  end

  test "a11201bcdu is consistent with a112012b — Oui iff breakdown has data" do
    result_gate = @survey.send(:a11201bcdu)
    result_breakdown = @survey.send(:a112012b)

    if result_breakdown.any?
      assert_equal "Oui", result_gate, "Gate must be Oui when UHNWI breakdown has data"
    else
      assert_equal "Non", result_gate, "Gate must be Non when UHNWI breakdown is empty"
    end
  end

  # === VASP Field Tests ===

  # Use compliance_test_org which has VASP fixtures:
  # - vasp_exchange_fr (EXCHANGE, incorporation_country: FR)
  # - vasp_custodian_lu (CUSTODIAN, incorporation_country: LU)
  # - vasp_ico_ch (ICO, incorporation_country: CH)
  # - vasp_other_mc (OTHER, incorporation_country: MC)

  test "a13602a returns Hash of VASP exchange clients grouped by country" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a13602a)

    assert_kind_of Hash, result
    assert_equal 1, result.values.sum
    assert_equal 1, result["FR"]
  end

  test "a13602b returns Hash of VASP custodian clients grouped by country" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a13602b)

    assert_kind_of Hash, result
    assert_equal 1, result.values.sum
    assert_equal 1, result["LU"]
  end

  test "a13602c returns Hash of VASP ICO clients grouped by country" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a13602c)

    assert_kind_of Hash, result
    assert_equal 1, result.values.sum
    assert_equal 1, result["CH"]
  end

  test "a13602d returns Hash of VASP other clients grouped by country" do
    org = organizations(:compliance_test_org)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a13602d)

    assert_kind_of Hash, result
    assert_equal 1, result.values.sum
    assert_equal 1, result["MC"]
  end

  test "a13602a returns empty Hash when no VASP exchange clients exist" do
    org = organizations(:two)
    survey = Survey.new(organization: org, year: Date.current.year)

    result = survey.send(:a13602a)

    assert_kind_of Hash, result
    assert result.empty?
  end

  test "a13604e returns setting value for other VASP services description" do
    result = @survey.send(:a13604e)

    # No setting configured in default org, should be nil
    assert_nil result
  end

end
