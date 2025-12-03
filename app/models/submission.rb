# frozen_string_literal: true

# Submission model for annual AMSF reporting.
# Tracks submission lifecycle: draft → in_review → validated → completed
#
# Each organization can have one submission per year.
# Submission values are captured as snapshots for historical accuracy.
#
class Submission < ApplicationRecord
  include AmsfConstants
  include Auditable

  # === Associations ===
  belongs_to :organization
  has_many :submission_values, dependent: :destroy
  accepts_nested_attributes_for :submission_values

  # === Validations ===
  validates :year, presence: true,
                   numericality: {
                     only_integer: true,
                     greater_than_or_equal_to: 2000,
                     less_than_or_equal_to: 2099
                   }
  validates :year, uniqueness: { scope: :organization_id }
  validates :status, presence: true, inclusion: { in: SUBMISSION_STATUSES }
  validates :taxonomy_version, presence: true

  # === Callbacks ===
  before_validation :set_defaults, on: :create

  # === Scopes ===
  scope :drafts, -> { where(status: "draft") }
  scope :in_review, -> { where(status: "in_review") }
  scope :validated_submissions, -> { where(status: "validated") }
  scope :completed_submissions, -> { where(status: "completed") }
  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_year, ->(year) { where(year: year) }
  scope :recent_first, -> { order(year: :desc) }

  # === State Machine Methods ===

  # State inquiry methods
  def draft?
    status == "draft"
  end

  def in_review?
    status == "in_review"
  end

  def validated?
    status == "validated"
  end

  def completed?
    status == "completed"
  end

  # State transition methods with guards
  def start_review!
    raise InvalidTransition, "Can only start review from draft status" unless draft?

    update!(status: "in_review")
  end

  # Named validate_submission! to avoid conflict with ActiveRecord::Validations#validate!
  def validate_submission!
    raise InvalidTransition, "Can only validate from in_review status" unless in_review?

    update!(status: "validated", validated_at: Time.current)
  end

  def complete!
    raise InvalidTransition, "Can only complete from validated status" unless validated?

    update!(status: "completed", completed_at: Time.current)
  end

  def reject!
    raise InvalidTransition, "Can only reject from in_review status" unless in_review?

    update!(status: "draft")
  end

  # State transition predicates (check if transition is valid)
  def may_start_review?
    draft?
  end

  def may_validate_submission?
    in_review?
  end

  def may_complete?
    validated?
  end

  def may_reject?
    in_review?
  end

  # === Helper Methods ===

  def editable?
    draft? || in_review?
  end

  def downloadable?
    validated? || completed? || downloaded_unvalidated?
  end

  # Returns the end of year date for this submission
  def report_date
    Date.new(year, 12, 31)
  end

  def status_badge_class
    case status
    when "draft" then "bg-gray-100 text-gray-800"
    when "in_review" then "bg-yellow-100 text-yellow-800"
    when "validated" then "bg-blue-100 text-blue-800"
    when "completed" then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def status_label
    case status
    when "draft" then "Draft"
    when "in_review" then "In Review"
    when "validated" then "Validated"
    when "completed" then "Completed"
    else status.humanize
    end
  end

  # === Custom Exception ===
  # Named to match AASM-style exception pattern for consistency
  class InvalidTransition < StandardError; end

  private

  def set_defaults
    self.status ||= "draft"
    self.taxonomy_version ||= ENV.fetch("AMSF_TAXONOMY_VERSION", "2025")
    self.started_at ||= Time.current
  end
end
