# frozen_string_literal: true

# Provides organization-scoped data access for multi-tenant CRM controllers.
# Include this concern in controllers that need to access organization-specific data.
#
# Ensures all queries are scoped to the current organization and provides
# helper methods for accessing organization-level resources.
#
# Note: current_organization is defined in ApplicationController and available as
# a helper_method. This concern adds the requirement that organization must exist.
module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_organization
  end

  private

  # Ensures an organization exists for the current account.
  # Redirects to onboarding if organization is missing, with fallback to root.
  def require_organization
    return if current_organization.present?

    # Fallback to root_path if onboarding route not yet defined
    redirect_path = respond_to?(:new_onboarding_path) ? new_onboarding_path : root_path
    redirect_to redirect_path, alert: "Please complete your organization setup."
  end

  # Helper to scope queries to the current organization.
  # Usage: organization_scope(Client) => Client.where(organization: current_organization)
  def organization_scope(model_class)
    model_class.where(organization: current_organization)
  end

  # Safely find a record by ID, scoped to the current organization.
  # Returns 404 if not found (security: don't reveal existence of records in other orgs).
  def find_organization_record(model_class, id)
    organization_scope(model_class).find(id)
  rescue ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound, "#{model_class.name} not found"
  end
end
