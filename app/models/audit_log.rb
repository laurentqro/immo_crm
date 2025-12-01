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
  validate :validate_metadata_values

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

  def validate_metadata_values
    return if metadata.blank?

    # Validate ip_address format if present
    if metadata["ip_address"].present?
      unless metadata["ip_address"].is_a?(String) && metadata["ip_address"].length <= 45
        errors.add(:metadata, "ip_address must be a string (max 45 chars)")
      end
    end

    # Validate user_agent is a string with reasonable length
    if metadata["user_agent"].present?
      unless metadata["user_agent"].is_a?(String) && metadata["user_agent"].length <= 500
        errors.add(:metadata, "user_agent must be a string (max 500 chars)")
      end
    end

    # Validate changed_fields is an array of strings
    if metadata["changed_fields"].present?
      unless metadata["changed_fields"].is_a?(Array) &&
             metadata["changed_fields"].all? { |f| f.is_a?(String) }
        errors.add(:metadata, "changed_fields must be an array of strings")
      end
    end
  end
end
