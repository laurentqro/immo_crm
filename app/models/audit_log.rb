# frozen_string_literal: true

require "ipaddr"

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
  # DESIGN DECISION: String enum vs integer enum
  # - Chose strings for better debugging and DB readability (~7 bytes vs 2 per record)
  # - Trade-off acceptable: compliance audit logs are relatively low-volume
  # - If high-volume logging needed, consider integer enum or separate logging service
  #
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

    # Validate ip_address format if present (IPv4 or IPv6)
    if metadata["ip_address"].present?
      validate_ip_address_format(metadata["ip_address"])
    end

    # Validate user_agent is a string with reasonable length
    if metadata["user_agent"].present?
      unless metadata["user_agent"].is_a?(String) && metadata["user_agent"].length <= 500
        errors.add(:metadata, "user_agent must be a string (max 500 chars)")
      end
    end

    # Validate changed_fields is an array of strings with reasonable limit
    if metadata["changed_fields"].present?
      fields = metadata["changed_fields"]
      unless fields.is_a?(Array) && fields.length <= 100 && fields.all? { |f| f.is_a?(String) }
        errors.add(:metadata, "changed_fields must be an array of strings (max 100 items)")
      end
    end
  end

  # Validate IP address format using Ruby's IPAddr
  # Accepts both IPv4 (max 15 chars) and IPv6 (max 45 chars)
  def validate_ip_address_format(ip)
    return if ip.blank?

    unless ip.is_a?(String) && ip.length <= 45
      errors.add(:metadata, "ip_address must be a string (max 45 chars)")
      return
    end

    IPAddr.new(ip)
  rescue IPAddr::InvalidAddressError
    errors.add(:metadata, "ip_address must be a valid IPv4 or IPv6 address")
  end
end
