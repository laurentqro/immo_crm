# frozen_string_literal: true

# Authorization policy for Setting model.
# Settings are organization-level configuration - all users in an account
# can view and update settings for their organization.
class SettingPolicy < ApplicationPolicy
  # Users can view settings for their organization
  # When authorizing the class (singular resource), allow all authenticated users
  def show?
    record.is_a?(Class) || belongs_to_organization?
  end

  # Users can update settings in their organization
  # When authorizing the class (batch update), allow all authenticated users
  def update?
    record.is_a?(Class) || belongs_to_organization?
  end

  private

  # Check if the setting belongs to the user's current organization
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
      # Only return settings for the current account's organization
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.where(organization: org)
    end
  end
end
