# frozen_string_literal: true

# Provides organization-scoped data access for multi-tenant CRM controllers.
# Include this concern in controllers that need to access organization-specific data.
#
# Ensures all queries are scoped to the current organization and provides
# helper methods for accessing organization-level resources.
module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_organization
    helper_method :current_organization
  end

  private

  # Returns the organization for the current account.
  # Returns nil if organization doesn't exist yet (user needs onboarding).
  def current_organization
    @current_organization ||= current_account&.organization
  end

  # Ensures an organization exists for the current account.
  # Redirects to onboarding if organization is missing.
  def require_organization
    return if current_organization.present?

    redirect_to new_onboarding_path, alert: "Please complete your organization setup."
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
