# frozen_string_literal: true

module Submissions
  # Validates a submission's XBRL output (if Arelle is enabled).
  #
  # Usage:
  #   result = Submissions::Validate.call(submission: submission)
  #   result.success?  # => true/false
  #   result.record    # => { valid: true/false, errors: [...] }
  #
  class Validate
    def self.call(submission:)
      new(submission: submission).call
    end

    def initialize(submission:)
      @submission = submission
    end

    def call
      valid = @submission.validate_xbrl

      data = {
        submission_id: @submission.id,
        year: @submission.year,
        valid: valid,
        errors: @submission.errors[:xbrl]
      }

      if valid
        ServiceResult.success(data)
      else
        ServiceResult.failure(errors: @submission.errors[:xbrl])
      end
    end
  end
end
