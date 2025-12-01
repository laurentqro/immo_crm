# frozen_string_literal: true

# STR Report model for tracking Suspicious Transaction Reports.
# Part of the CRM for Monaco real estate AML/CFT compliance.
#
# STR Reasons (AMSF terminology):
# - CASH: Cash payment exceeding threshold
# - PEP: Politically Exposed Person involvement
# - UNUSUAL_PATTERN: Unusual transaction pattern
# - OTHER: Other suspicious activity
#
class StrReport < ApplicationRecord
  include AmsfConstants
  include Auditable
  include Discard::Model
  self.discard_column = :deleted_at

  # === Associations ===
  belongs_to :organization
  belongs_to :client, optional: true
  # Note: Can't use 'transaction' as association name - conflicts with AR method
  belongs_to :linked_transaction, class_name: "Transaction", optional: true, foreign_key: "transaction_id"

  # === Validations ===
  validates :report_date, presence: true
  validates :reason, presence: true, inclusion: { in: STR_REASONS }

  # Ensure client belongs to the same organization (if provided)
  validate :client_belongs_to_organization
  validate :transaction_belongs_to_organization

  # === Scopes ===

  # Year filtering
  scope :for_year, ->(year) {
    where(report_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
  }

  # Reason filtering
  scope :by_reason, ->(reason) { where(reason: reason) }

  # Association presence scopes
  scope :with_client, -> { where.not(client_id: nil) }
  scope :with_transaction, -> { where.not(transaction_id: nil) }

  # Ordering
  scope :recent, -> { order(report_date: :desc) }

  # Organization scope (for policy/controller use)
  scope :for_organization, ->(org) { where(organization: org) }

  # === Instance Methods ===

  # For display purposes
  def reason_label
    case reason
    when "CASH" then "Cash Payment"
    when "PEP" then "PEP Involvement"
    when "UNUSUAL_PATTERN" then "Unusual Pattern"
    when "OTHER" then "Other"
    else reason
    end
  end

  private

  def client_belongs_to_organization
    return unless client.present? && organization.present?
    return if client.organization_id == organization_id

    errors.add(:client, "must belong to the same organization")
  end

  def transaction_belongs_to_organization
    return unless linked_transaction.present? && organization.present?
    return if linked_transaction.organization_id == organization_id

    errors.add(:linked_transaction, "must belong to the same organization")
  end
end
