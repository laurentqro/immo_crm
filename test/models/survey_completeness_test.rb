# frozen_string_literal: true

require "test_helper"

# This test ensures Survey implements all questionnaire fields from the amsf_survey gem.
# It serves as a CI safety net: when the gem is updated with new fields,
# this test fails until the app implements corresponding methods.
#
# The test checks that Survey responds to each field ID (e.g., :a1101, :a1102).
# Fields without implementations will cause survey values to be nil,
# which may cause validation failures or incomplete submissions.
class SurveyCompletenessTest < ActiveSupport::TestCase
  test "Survey implements all questionnaire fields" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
    survey = Survey.new(organization: organizations(:one), year: 2025)

    missing = questionnaire.questions.map { |q| q.id.to_s.downcase.to_sym }.reject do |question_id|
      survey.respond_to?(question_id, true)
    end

    assert missing.empty?, "Survey missing implementations for: #{missing.join(", ")}"
  end

  test "compliance_policies_author setting options match gem valid_values for aC1208" do
    question = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025).question(:ac1208)

    # These values must match the select options in app/views/settings/show.html.erb
    app_values = [
      "Par l'entité",
      "Par un autre membre du groupe",
      "Par des consultants externes",
      "Combinaison de soi, membre ou externe"
    ]

    assert_equal app_values.sort, question.valid_values.sort,
      "Settings dropdown values for compliance_policies_author must match gem's aC1208 valid_values"
  end
end
