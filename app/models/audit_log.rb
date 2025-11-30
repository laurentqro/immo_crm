# frozen_string_literal: true

# Compliance audit trail for authentication and data changes.
# Records login/logout, CRUD operations on sensitive models, and file downloads.
class AuditLog < ApplicationRecord
  include AmsfConstants

  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true, inclusion: { in: AUDIT_ACTIONS }

  # Scopes for common queries
  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_action, ->(action) { where(action: action) }
  scope :recent, -> { order(created_at: :desc) }
  scope :auth_events, -> { where(action: %w[login logout login_failed]) }
  scope :data_events, -> { where(action: %w[create update delete download]) }

  # For 5-year retention cleanup
  scope :older_than, ->(date) { where("created_at < ?", date) }
end
