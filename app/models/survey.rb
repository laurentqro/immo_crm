# frozen_string_literal: true

# Survey is a read-only value calculator for AMSF submissions.
# Given an organization and year, it produces values for all questionnaire fields
# by calling methods named after field IDs (e.g., a1101, a1102).
#
# The amsf_survey gem handles XML generation and validation.
# This class uses field IDs directly - no semantic name indirection.
#
# Usage:
#   survey = Survey.new(organization: org, year: 2025)
#   survey.to_xbrl  # => XML string
#   survey.valid?   # => true/false
#
class Survey
  include Survey::Fields::CustomerRisk
  include Survey::Fields::ProductsServicesRisk
  include Survey::Fields::DistributionRisk
  include Survey::Fields::Controls
  include Survey::Fields::Signatories

  attr_reader :organization, :year

  def initialize(organization:, year:)
    @organization = organization
    @year = year
  end

  def to_xbrl
    AmsfSurvey.to_xbrl(submission, pretty: true)
  end

  def valid?
    validation_result.valid?
  end

  def errors
    validation_result.errors
  end

  private

  def validation_result
    @validation_result ||= AmsfSurvey.validate(submission)
  end

  def questionnaire
    @questionnaire ||= AmsfSurvey.questionnaire(industry: :real_estate, year: year)
  end

  def submission
    @submission ||= build_submission
  end

  def build_submission
    sub = AmsfSurvey.build_submission(
      industry: :real_estate,
      year: year,
      entity_id: organization.rci_number,
      period: Date.new(year, 12, 31)
    )

    populate_fields(sub)
    sub
  end

  def populate_fields(sub)
    questionnaire.fields.each do |field|
      field_id = field.id.downcase.to_sym
      next unless respond_to?(field_id, true)

      value = send(field_id)
      sub[field.name] = value if value.present?
    end
  end
end
