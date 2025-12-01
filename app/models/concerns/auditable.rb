# frozen_string_literal: true

# Adds audit logging callbacks to models for compliance tracking.
# Records create, update, and delete (soft) actions to AuditLog.
#
# IMPORTANT: For models using Discard for soft deletes, include Discard::Model
# BEFORE including Auditable to ensure the after_discard callback is registered:
#
#   class Client < ApplicationRecord
#     include Discard::Model  # Must come first
#     include Auditable
#   end
#
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create :log_audit_create
    after_update :log_audit_update

    # Hook into Discard's soft delete if the model has already included Discard::Model
    # The class must include Discard::Model before Auditable for this to work
    if included_modules.any? { |m| m.name == "Discard::Model" }
      after_discard :log_audit_delete
    end
  end

  private

  def log_audit_create
    log_audit("create")
  end

  def log_audit_update
    log_audit("update", changed_fields: previous_changes.keys - %w[created_at updated_at])
  end

  def log_audit_delete
    log_audit("delete")
  end

  def log_audit(action, metadata = {})
    return unless defined?(AuditLog)

    # Determine organization_id for audit scoping
    # Special case: Organization model audits itself
    org_id = if is_a?(Organization)
      id
    elsif respond_to?(:organization)
      organization&.id
    elsif respond_to?(:organization_id)
      organization_id
    else
      Rails.logger.warn("Auditable: #{self.class.name} lacks organization/organization_id - audit skipped")
      return
    end

    # Current.user/ip_address/user_agent are set by SetCurrentRequestDetails concern
    # (included in ApplicationController, part of Jumpstart Pro base).
    # See: app/controllers/concerns/set_current_request_details.rb
    AuditLog.create!(
      organization_id: org_id,
      user_id: Current.user&.id,
      action: action,
      auditable: self,
      metadata: metadata.merge(
        ip_address: Current.ip_address,
        user_agent: Current.user_agent
      ).compact
    )
  rescue => e
    # Don't let audit logging failures break the main operation
    Rails.logger.error("Audit logging failed: #{e.message}")
  end
end
