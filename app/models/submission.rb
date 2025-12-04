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
  belongs_to :locked_by_user, class_name: "User", optional: true
  has_many :submission_values, dependent: :destroy
  accepts_nested_attributes_for :submission_values

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

  # === Locking Methods (FR-029) ===

  # Lock timeout in minutes - stale locks are automatically released
  LOCK_TIMEOUT = 30.minutes

  # Atomically lock the submission to prevent race conditions.
  # Uses database-level row locking (SELECT FOR UPDATE) to ensure atomicity.
  # Automatically releases stale locks (older than LOCK_TIMEOUT).
  # Returns true if lock was acquired, raises LockError if already locked by another user.
  def acquire_lock!(user)
    transaction do
      reload(lock: true) # SELECT ... FOR UPDATE

      # Release stale locks automatically
      if stale_lock?
        update!(locked_by_user_id: nil, locked_at: nil)
      elsif locked? && !locked_by?(user)
        raise LockError, "Submission is already locked by another user"
      end

      update!(locked_by_user_id: user.id, locked_at: Time.current)
    end
    true
  end

  # Atomically unlock the submission.
  # Only the user who holds the lock (or force unlock) can release it.
  def release_lock!(user = nil, force: false)
    transaction do
      reload(lock: true) # SELECT ... FOR UPDATE

      if locked? && !force && user.present? && !locked_by?(user)
        raise LockError, "Cannot unlock submission locked by another user"
      end

      update!(locked_by_user_id: nil, locked_at: nil)
    end
    true
  end

  def locked?
    locked_by_user_id.present? && locked_at.present? && !stale_lock?
  end

  def locked_by?(user)
    locked_by_user_id == user.id
  end

  # Check if lock is stale (older than LOCK_TIMEOUT)
  # Stale locks should be released to prevent indefinite blocking
  def stale_lock?
    locked_at.present? && locked_at < LOCK_TIMEOUT.ago
  end

  # Custom exception for locking errors
  class LockError < StandardError; end

  # === Reopen Method (FR-025) ===

  def reopen!
    raise InvalidTransition, "Can only reopen completed submissions" unless completed?

    transaction do
      previous_status = status
      update!(
        status: "draft",
        reopened_count: reopened_count + 1,
        generated_at: nil
      )

      # Create audit log entry for compliance tracking
      log_audit("reopen", previous_status: previous_status, reopened_count: reopened_count)
    end
  end

  # === Generate Method (FR-024) ===

  def generate!
    raise InvalidTransition, "Can only generate from validated status" unless validated?

    update!(
      status: "completed",
      generated_at: Time.current,
      completed_at: Time.current
    )
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

  # Render submission as Markdown for `render markdown: @submission`
  def to_markdown
    SubmissionRenderer.new(self).to_markdown
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
