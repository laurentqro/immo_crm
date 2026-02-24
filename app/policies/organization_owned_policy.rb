# frozen_string_literal: true

# Base policy for models that belong_to :organization.
# Provides standard index/create/destroy authorization and org-scoped queries.
class OrganizationOwnedPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def destroy?
    belongs_to_organization?
  end

  private

  def belongs_to_organization?
    record.organization_id == current_organization&.id
  end

  def current_organization
    account_user.account.organization
  end

  class Scope < Scope
    def resolve
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.where(organization: org)
    end
  end
end
