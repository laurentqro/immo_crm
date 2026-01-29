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
end
