# frozen_string_literal: true

# Authorization policy for Training records.
# Ensures trainings are scoped to the user's current organization.
class TrainingPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    belongs_to_organization?
  end

  def new?
    true
  end

  def create?
    true
  end

  def edit?
    belongs_to_organization?
  end

  def update?
    belongs_to_organization?
  end

  def destroy?
    belongs_to_organization?
  end

  def permitted_attributes
    %i[
      training_date
      training_type
      topic
      provider
      staff_count
      duration_hours
      notes
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
