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
    questionnaire.fields.each do |field|
      method_name = field.id.downcase.to_sym
      next unless respond_to?(method_name, true)

      value = send(method_name)
      result[method_name.to_s] = value
    end
    result
  end

  # Returns the questionnaire structure from the gem.
  # Use this to access sections/tabs and field metadata (labels, types, etc.)
  def questionnaire
    @questionnaire ||= AmsfSurvey.questionnaire(industry: :real_estate, year: year)
  end

  # Looks up a field by ID and returns its label (the full question text).
  # Returns nil if field not found.
  def question_label(question_id)
    question = questionnaire.questions.find { |q| q.id.to_s.downcase == question_id.to_s.downcase }
    question&.label
  end

  # Returns the calculated value for a field by ID.
  # Returns nil if the question method is not implemented.
  def answer(question_id)
    method_name = question_id.to_s.downcase.to_sym
    return nil unless respond_to?(method_name, true)

    send(method_name)
  end

  # Returns tabs with their question IDs, derived from the Question modules.
  # Each tab corresponds to a Survey::Fields module.
  # Questions are sorted by the gem's display order attribute.
  def tabs
    @tabs ||= [
      {key: :customer_risk, title: "Customer Risk", module: Fields::CustomerRisk},
      {key: :products_services_risk, title: "Products/Services Risk", module: Fields::ProductsServicesRisk},
      {key: :distribution_risk, title: "Distribution Risk", module: Fields::DistributionRisk},
      {key: :controls, title: "Controls", module: Fields::Controls},
      {key: :signatories, title: "Signatories", module: Fields::Signatories}
    ].map do |tab|
      question_ids = tab[:module].private_instance_methods(false)
        .map(&:to_s)
        .reject { |m| helper_method?(m) }

      # Sort by gem's display order
      sorted_questions = question_ids.sort_by { |id| question_order(id) }
      tab.merge(questions: sorted_questions)
    end
  end

  # Helper methods are not field IDs - they support field calculations
  HELPER_METHODS = %w[
    clients_kept year_transactions beneficial_owners_base
    setting_value settings_cache clients_by_sector
    vasp_transactions_by_type vasp_funds_by_type vasp_clients_by_country
  ].freeze

  def helper_method?(method_name)
    HELPER_METHODS.include?(method_name)
  end

  # Returns the display order for a field from the gem questionnaire.
  # Uses the gem's field array index as the order (array is already sorted).
  # Fields not in the questionnaire sort to the end.
  def question_order(question_id)
    @question_orders ||= questionnaire.questions.each_with_index.each_with_object({}) do |(q, index), hash|
      hash[q.id.to_s.downcase] = index
    end
    @question_orders[question_id.to_s.downcase] || Float::INFINITY
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
