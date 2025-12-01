# frozen_string_literal: true

# Authorization policy for StrReport model.
# STR Reports are scoped to Organizations, which are tied to Accounts.
# All users in an account can manage STR reports for that account's organization.
class StrReportPolicy < ApplicationPolicy
  # All authenticated users can list STR reports in their organization
  def index?
    true
  end

  # Users can view STR reports belonging to their organization
  def show?
    belongs_to_organization?
  end

  # All users can create STR reports for their organization
  def create?
    true
  end

  def new?
    create?
  end

  # All users can update STR reports in their organization
  def update?
    belongs_to_organization?
  end

  def edit?
    update?
  end

  # All users can soft-delete STR reports in their organization
  def destroy?
    belongs_to_organization?
  end

  # Define which attributes users can set
  def permitted_attributes
    [
      :client_id,
      :transaction_id,
      :report_date,
      :reason,
      :notes
    ]
  end

  private

  # Check if the STR report belongs to the user's current organization
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
      # Only return STR reports for the current account's organization
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.kept.where(organization: org)
    end
  end
end
