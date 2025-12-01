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

    # Models must define organization or organization_id for proper audit scoping
    unless respond_to?(:organization) || respond_to?(:organization_id)
      Rails.logger.warn("Auditable: #{self.class.name} lacks organization/organization_id - audit skipped")
      return
    end

    org = respond_to?(:organization) ? organization : nil
    org_id = org&.id || try(:organization_id)

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
  rescue StandardError => e
    # Don't let audit logging failures break the main operation
    Rails.logger.error("Audit logging failed: #{e.message}")
  end
end
