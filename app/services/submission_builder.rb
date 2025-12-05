# frozen_string_literal: true

# SubmissionBuilder orchestrates the submission workflow:
# 1. Creates or retrieves a Submission for the organization/year
# 2. Populates calculated values from CRM data
# 3. Generates XBRL XML
# 4. Validates against external validator
#
# Usage:
#   builder = SubmissionBuilder.new(organization, year: 2025)
#   result = builder.build
#   if result.success?
#     xbrl = builder.generate_xbrl
#     validation = builder.validate
#   end
#
class SubmissionBuilder
  attr_reader :organization, :year, :submission

  def initialize(organization, year: Date.current.year)
    @organization = organization
    @year = year
    @submission = nil
    @built = false
  end

  # Build or retrieve the submission and populate values
  #
  # @return [Result] Result object with success status, submission, and errors
  def build
    @submission = find_or_create_submission
    return Result.failure(submission.errors.full_messages) unless submission.persisted?

    populate_values
    @built = true

    Result.success(submission)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure([e.message])
  end

  # Generate XBRL XML from the submission
  #
  # @return [String] XBRL XML content
  # @raise [NotBuiltError] if build hasn't been called
  def generate_xbrl
    raise NotBuiltError, "Call build before generate_xbrl" unless @built

    SubmissionRenderer.new(submission).to_xbrl
  end

  # Validate the XBRL content against the external validator
  #
  # @return [Hash] Validation result with :valid, :errors, :warnings
  # @raise [NotBuiltError] if build hasn't been called
  def validate
    raise NotBuiltError, "Call build before validate" unless @built

    xbrl_content = generate_xbrl
    ValidationService.new(xbrl_content).validate
  end

  # Result object for build operations
  class Result
    attr_reader :submission, :errors

    def initialize(success:, submission: nil, errors: [])
      @success = success
      @submission = submission
      @errors = errors
    end

    def success?
      @success
    end

    def self.success(submission)
      new(success: true, submission: submission, errors: [])
    end

    def self.failure(errors)
      new(success: false, submission: nil, errors: errors)
    end
  end

  # Error raised when methods are called before build
  class NotBuiltError < StandardError; end

  private

  def find_or_create_submission
    Submission.find_or_create_by!(organization: organization, year: year)
  rescue ActiveRecord::RecordInvalid => e
    # Return a new invalid submission with errors for the result
    invalid = Submission.new(organization: organization, year: year)
    invalid.valid? # Populate errors
    invalid
  end

  def populate_values
    CalculationEngine.new(submission).populate_submission_values!
  end
end
