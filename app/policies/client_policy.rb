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
      :became_client_at,
      :business_sector,
      :client_type,
      :due_diligence_level,
      :incorporation_country,
      :introduced_by_third_party,
      :introducer_country,
      :is_pep,
      :is_vasp,
      :legal_entity_type,
      :legal_entity_type_other,
      :name,
      :nationality,
      :notes,
      :pep_type,
      :professional_category,
      :rejection_reason,
      :relationship_end_reason,
      :relationship_ended_at,
      :residence_country,
      :risk_level,
      :simplified_dd_reason,
      :source_of_funds_verified,
      :source_of_wealth_verified,
      :third_party_cdd,
      :third_party_cdd_country,
      :third_party_cdd_type,
      :vasp_other_service_type,
      :vasp_type,
      trustees_attributes: [:id, :_destroy, :is_professional, :name, :nationality]
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
