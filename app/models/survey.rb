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
    submission.complete?
  end

  def unanswered_questions
    submission.unanswered_questions
  end

  def completion_percentage
    submission.completion_percentage
  end

  # Returns all calculated field values as a hash.
  # Keys are field ID strings (e.g., "a1101"), values are the calculated results.
  # Only includes fields that have corresponding methods implemented.
  def to_hash
    result = {}
    questionnaire.questions.each do |question|
      method_name = question.id.to_s.downcase.to_sym
      next unless respond_to?(method_name, true)

      value = send(method_name)
      result[method_name.to_s] = value
    end
    result
  end

  # Returns the questionnaire structure from the gem.
  # Use this to access sections, subsections, and questions with all metadata.
  def questionnaire
    @questionnaire ||= AmsfSurvey.questionnaire(industry: :real_estate, year: year)
  end

  # Returns the sections from the gem questionnaire.
  # Each section has a title and contains subsections.
  def sections
    questionnaire.sections
  end

  # Looks up a question by ID and returns the Question object.
  # Returns nil if not found.
  def question(question_id)
    questionnaire.question(question_id.to_s.downcase.to_sym)
  end

  # Returns the calculated value for a question by ID.
  # Returns nil if the question method is not implemented.
  def answer(question_id)
    method_name = question_id.to_s.downcase.to_sym
    return nil unless respond_to?(method_name, true)

    send(method_name)
  end

  private

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
    questionnaire.questions.each do |question|
      question_id = question.id.downcase.to_sym
      next unless respond_to?(question_id, true)

      value = send(question_id)
      sub[question.id] = value if value.present?
    end
  end
end
