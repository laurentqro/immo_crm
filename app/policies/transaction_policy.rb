# frozen_string_literal: true

# Authorization policy for Transaction model.
# Transactions are scoped to Organizations, which are tied to Accounts.
# All users in an account can manage transactions for that account's organization.
class TransactionPolicy < ApplicationPolicy
  # All authenticated users can list transactions in their organization
  def index?
    true
  end

  # Users can view transactions belonging to their organization
  def show?
    belongs_to_organization?
  end

  # All users can create transactions for their organization
  def create?
    true
  end

  def new?
    create?
  end

  # All users can update transactions in their organization
  def update?
    belongs_to_organization?
  end

  def edit?
    update?
  end

  # All users can soft-delete transactions in their organization
  def destroy?
    belongs_to_organization?
  end

  # Define which attributes users can set
  def permitted_attributes
    [
      :client_id,
      :reference,
      :transaction_date,
      :transaction_type,
      :transaction_value,
      :commission_amount,
      :property_country,
      :payment_method,
      :cash_amount,
      :agency_role,
      :purchase_purpose,
      :notes
    ]
  end

  private

  # Check if the transaction belongs to the user's current organization
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
      # Only return transactions for the current account's organization
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.kept.where(organization: org)
    end
  end
end
