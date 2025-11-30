# frozen_string_literal: true

# Compliance audit trail for authentication and data changes.
# Records login/logout, CRUD operations on sensitive models, and file downloads.
#
# Uses Rails enum for action types with prefix to avoid AR method conflicts:
#   audit_log.action_login?   # Check if action is login
#   audit_log.action_create!  # Set action to create (bang method)
#   AuditLog.action_create    # Scope to create actions
#
class AuditLog < ApplicationRecord
  include AmsfConstants

  # Allowed keys in the metadata JSONB field
  ALLOWED_METADATA_KEYS = %w[ip_address user_agent changed_fields].freeze

  # Action types as Rails enum (stored as strings in DB for readability)
  # Using prefix to avoid conflicts with ActiveRecord methods (create, update, etc.)
  # Usage: audit_log.action_login?, AuditLog.action_create, etc.
  enum :action, {
    login: "login",
    logout: "logout",
    login_failed: "login_failed",
    create: "create",
    update: "update",
    delete: "delete",
    download: "download"
  }, prefix: true, validate: true

  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validate :validate_metadata_keys

  # Scopes for common queries
  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Composite scopes (individual action scopes provided by enum)
  scope :auth_events, -> { where(action: %w[login logout login_failed]) }
  scope :data_events, -> { where(action: %w[create update delete download]) }

  # For 5-year retention cleanup
  scope :older_than, ->(date) { where("created_at < ?", date) }

  private

  def validate_metadata_keys
    return if metadata.blank?

    invalid_keys = metadata.keys - ALLOWED_METADATA_KEYS
    return if invalid_keys.empty?

    errors.add(:metadata, "contains invalid keys: #{invalid_keys.join(', ')}")
  end
end
