# frozen_string_literal: true

# Authorization policy for Client model.
# Clients are scoped to Organizations, which are tied to Accounts.
# All users in an account can manage clients for that account's organization.
class ClientPolicy < ApplicationPolicy
  # All authenticated users can list clients in their organization
  def index?
    true
  end

  # Users can view clients belonging to their organization
  def show?
    belongs_to_organization?
  end

  # All users can create clients for their organization
  def create?
    true
  end

  def new?
    create?
  end

  # All users can update clients in their organization
  def update?
    belongs_to_organization?
  end

  def edit?
    update?
  end

  # All users can soft-delete clients in their organization
  def destroy?
    belongs_to_organization?
  end

  # Define which attributes users can set
  def permitted_attributes
    [
      :name,
      :client_type,
      :nationality,
      :residence_country,
      :is_pep,
      :pep_type,
      :risk_level,
      :is_vasp,
      :vasp_type,
      :legal_person_type,
      :business_sector,
      :became_client_at,
      :relationship_ended_at,
      :rejection_reason,
      :notes,
      # AMSF Compliance fields (US2)
      :due_diligence_level,
      :simplified_dd_reason,
      :professional_category,
      :relationship_end_reason,
      :source_of_funds_verified,
      :source_of_wealth_verified,
      # Trustee fields (for Trust clients)
      :trustee_name,
      :trustee_nationality,
      :trustee_country,
      :is_professional_trustee,
      # Introducer tracking fields
      :introduced_by_third_party,
      :introducer_country
    ]
  end

  private

  # Check if the client belongs to the user's current organization
  def belongs_to_organization?
    return false unless record.respond_to?(:organization_id)
    record.organization_id == current_organization&.id
  end

  # Get the organization for the current account
  def current_organization
    account_user.account.organization
  end

  class Scope < Scope
    def resolve
      # Only return clients for the current account's organization
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.kept.where(organization: org)
    end
  end
end
