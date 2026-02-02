# frozen_string_literal: true

# Authorization policy for BeneficialOwner model.
# Access is controlled through the parent Client's organization.
class BeneficialOwnerPolicy < ApplicationPolicy
  # All authenticated users can list beneficial owners
  def index?
    true
  end

  # Users can view beneficial owners of clients in their organization
  def show?
    client_belongs_to_organization?
  end

  # All users can create beneficial owners for their organization's clients
  def create?
    client_belongs_to_organization?
  end

  def new?
    create?
  end

  # All users can update beneficial owners in their organization
  def update?
    client_belongs_to_organization?
  end

  def edit?
    update?
  end

  # All users can delete beneficial owners in their organization
  def destroy?
    client_belongs_to_organization?
  end

  # Define which attributes users can set
  def permitted_attributes
    [
      :name,
      :nationality,
      :residence_country,
      :ownership_percentage,
      :control_type,
      :is_pep,
      :pep_type
    ]
  end

  private

  # Check if the beneficial owner's client belongs to the user's organization
  def client_belongs_to_organization?
    return false unless record.respond_to?(:client)
    return false unless record.client

    record.client.organization_id == current_organization&.id
  end

  # Get the organization for the current account
  def current_organization
    account_user.account.organization
  end

  class Scope < Scope
    def resolve
      # Only return beneficial owners for clients in the current organization
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.joins(:client).where(clients: { organization_id: org.id })
    end
  end
end
