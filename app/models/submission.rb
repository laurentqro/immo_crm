# frozen_string_literal: true

# Submission model for annual AMSF reporting.
# Tracks submission lifecycle: draft -> completed
#
# Each organization can have one submission per year.
# Answers capture manual overrides for calculated survey values.
#
class Submission < ApplicationRecord
  include AmsfConstants
  include Auditable

  # === Associations ===
  belongs_to :organization
  has_many :answers, dependent: :destroy

  # === Validations ===
  validates :year, presence: true,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: MIN_SUBMISSION_YEAR,
      less_than_or_equal_to: MAX_SUBMISSION_YEAR
    }
  validates :year, uniqueness: {scope: :organization_id}
  validates :status, presence: true, inclusion: {in: SUBMISSION_STATUSES}
  validates :taxonomy_version, presence: true

  # === Callbacks ===
  before_validation :set_defaults, on: :create

  # === Scopes ===
  scope :drafts, -> { where(status: "draft") }
  scope :completed_submissions, -> { where(status: "completed") }
  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_year, ->(year) { where(year: year) }
  scope :recent_first, -> { order(year: :desc) }

  # === State Methods ===

  def draft?
    status == "draft"
  end

  def completed?
    status == "completed"
  end

  def complete!
    raise InvalidTransition, "Can only complete from draft status" unless draft?

    update!(status: "completed", completed_at: Time.current)
  end

  # Validate XBRL output against Arelle API.
  # Adds errors to errors[:xbrl] if validation fails.
  #
  # Returns true if:
  #   - Arelle is disabled via config
  #   - XBRL passes validation
  # Returns false if validation errors found or service unavailable.
  #
  # @return [Boolean]
  def validate_xbrl
    return true unless AmsfValidationConfig.arelle_enabled?

    survey = Survey.new(organization: organization, year: year)
    result = survey.validate_with_arelle
    return true if result.valid?

    result.error_messages.each do |message|
      errors.add(:xbrl, message)
    end
    false
  rescue ArelleClient::ConnectionError => e
    Rails.logger.error("Arelle validation service unavailable: #{e.message}")
    errors.add(:xbrl, "Validation service temporarily unavailable. Please try again later.")
    false
  rescue AmsfSurvey::Error => e
    Rails.logger.error("XBRL generation failed during validation: #{e.message}")
    errors.add(:xbrl, e.message)
    false
  end

  # === Helper Methods ===

  def merged_answers
    survey = Survey.new(organization: organization, year: year)
    calculated = survey.to_hash
    manual = answers.pluck(:xbrl_id, :value).to_h
    calculated.merge(manual)
  end

  def editable?
    draft?
  end

  # Returns the end of year date for this submission
  def report_date
    Date.new(year, 12, 31)
  end

  def status_badge_class
    case status
    when "draft" then "bg-gray-100 text-gray-800"
    when "completed" then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def status_label
    case status
    when "draft" then "Draft"
    when "completed" then "Completed"
    else status.humanize
    end
  end

  # Render submission as Markdown for `render markdown: @submission`
  def to_markdown
    SubmissionRenderer.new(self).to_markdown
  end

  # === Custom Exception ===
  class InvalidTransition < StandardError; end

  private

  def set_defaults
    self.status ||= "draft"
    self.taxonomy_version ||= AmsfSurvey.supported_years(:real_estate).max.to_s
    self.started_at ||= Time.current
  end
end
