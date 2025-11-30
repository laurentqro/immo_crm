# frozen_string_literal: true

# Authorization policy for Organization model.
# Organizations are tied 1:1 to Accounts, so access is based on account membership.
class OrganizationPolicy < ApplicationPolicy
  # Users can view the organization for their current account
  def show?
    owns_organization?
  end

  # Only admins can update organization details
  def update?
    account_user.admin? && owns_organization?
  end

  def edit?
    update?
  end

  # Creating new organizations is handled during onboarding
  def create?
    account_user.admin?
  end

  def new?
    create?
  end

  # Organizations should not be deleted (soft delete clients/transactions instead)
  def destroy?
    false
  end

  private

  # Check if the record belongs to the user's current account
  def owns_organization?
    record.account_id == account_user.account_id
  end

  class Scope < Scope
    def resolve
      # Users can only see their own account's organization
      scope.where(account_id: account_user.account_id)
    end
  end
end
