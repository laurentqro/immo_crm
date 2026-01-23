# frozen_string_literal: true

# Survey is a read-only value calculator for AMSF submissions.
# Given an organization and year, it produces values for all questionnaire fields
# by calling semantic methods (e.g., total_clients, high_risk_clients).
#
# The amsf_survey gem handles XBRL codes and XML generation.
# This class knows nothing about XBRL - only semantic field names.
#
# Usage:
#   survey = Survey.new(organization: org, year: 2025)
#   survey.to_xbrl  # => XML string
#   survey.valid?   # => true/false
#
class Survey
  attr_reader :organization, :year

  def initialize(organization:, year:)
    @organization = organization
    @year = year
  end

  private

  def questionnaire
    @questionnaire ||= AmsfSurvey.questionnaire(industry: :real_estate, year: year)
  end
end
