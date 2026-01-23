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

    missing = questionnaire.fields.map { |f| f.id.downcase.to_sym }.reject do |field_id|
      survey.respond_to?(field_id, true)
    end

    assert missing.empty?, "Survey missing implementations for: #{missing.join(", ")}"
  end
end
