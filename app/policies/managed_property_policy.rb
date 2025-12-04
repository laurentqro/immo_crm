# frozen_string_literal: true

# Authorization policy for ManagedProperty model.
# Managed properties are scoped to Organizations.
class ManagedPropertyPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    belongs_to_organization?
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    belongs_to_organization?
  end

  def edit?
    update?
  end

  def destroy?
    belongs_to_organization?
  end

  def permitted_attributes
    [
      :client_id,
      :property_address,
      :property_type,
      :management_start_date,
      :management_end_date,
      :monthly_rent,
      :management_fee_percent,
      :management_fee_fixed,
      :tenant_name,
      :tenant_type,
      :tenant_country,
      :tenant_is_pep,
      :notes
    ]
  end

  private

  def belongs_to_organization?
    return false unless record.respond_to?(:organization_id)
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
