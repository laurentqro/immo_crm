# frozen_string_literal: true

module Submissions
  # Validates and completes a draft submission.
  #
  # Usage:
  #   result = Submissions::Complete.call(submission: submission)
  #   result.success?  # => true if validated + completed
  #
  class Complete
    def self.call(submission:)
      new(submission: submission).call
    end

    def initialize(submission:)
      @submission = submission
    end

    def call
      unless @submission.draft?
        return ServiceResult.failure(
          record: @submission,
          errors: ["Submission is already completed"]
        )
      end

      unless @submission.validate_xbrl
        return ServiceResult.failure(
          record: @submission,
          errors: @submission.errors[:xbrl].presence || ["XBRL validation failed"]
        )
      end

      @submission.complete!
      ServiceResult.success(@submission)
    rescue Submission::InvalidTransition => e
      ServiceResult.failure(record: @submission, errors: [e.message])
    end
  end
end
