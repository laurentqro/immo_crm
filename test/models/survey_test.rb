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
end
