# frozen_string_literal: true

module Submissions
  # Generates a survey preview for a submission year.
  # Returns all calculated field values without creating XBRL.
  #
  # Usage:
  #   result = Submissions::Generate.call(organization: org, year: 2025)
  #   result.record  # => { fields: { "a1101" => 42, ... }, completion: 95.5, valid: true }
  #
  class Generate
    def self.call(organization:, year:)
      new(organization: organization, year: year).call
    end

    def initialize(organization:, year:)
      @organization = organization
      @year = year
    end

    def call
      survey = Survey.new(organization: @organization, year: @year)

      data = {
        organization_id: @organization.id,
        year: @year,
        fields: survey.to_hash,
        completion_percentage: survey.completion_percentage,
        unanswered_questions: survey.unanswered_questions.map(&:id),
        valid: survey.valid?
      }

      ServiceResult.success(data)
    rescue => e
      ServiceResult.failure(errors: [e.message])
    end
  end
end
