# frozen_string_literal: true

require "test_helper"

# This test ensures Survey implements all questionnaire fields from the amsf_survey gem.
# It serves as a CI safety net: when the gem is updated with new fields,
# this test fails until the app implements corresponding methods.
#
# The test checks that Survey responds to each semantic field name defined
# in the questionnaire (e.g., :total_clients, :high_risk_clients).
# Fields without implementations will cause survey values to be nil,
# which may cause validation failures or incomplete submissions.
class SurveyCompletenessTest < ActiveSupport::TestCase
  test "Survey implements all questionnaire fields" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
    survey = Survey.new(organization: organizations(:one), year: 2025)

    missing = questionnaire.fields.map(&:name).reject do |name|
      survey.respond_to?(name, true)
    end

    assert missing.empty?, "Survey missing implementations for: #{missing.join(", ")}"
  end
end
