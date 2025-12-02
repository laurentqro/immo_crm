# frozen_string_literal: true

# Authorization policy for Submission model.
# Submissions are scoped to Organizations and have lifecycle constraints.
class SubmissionPolicy < ApplicationPolicy
  # All authenticated users can list submissions in their organization
  def index?
    true
  end

  # Users can view submissions belonging to their organization
  def show?
    belongs_to_organization?
  end

  # All users can create submissions for their organization
  def create?
    true
  end

  def new?
    create?
  end

  # Users can update submissions in their organization that are still editable
  def update?
    belongs_to_organization? && record.editable?
  end

  def edit?
    update?
  end

  # Users can attempt to delete submissions in their organization
  # Business logic about which submissions can be deleted is in the controller
  def destroy?
    belongs_to_organization?
  end

  # Download is allowed for validated/completed submissions,
  # or draft submissions with explicit unvalidated flag
  def download?
    belongs_to_organization? && record.downloadable?
  end

  # Define which attributes users can set
  def permitted_attributes
    [
      :year,
      :taxonomy_version,
      :status,
      submission_values_attributes: [:id, :element_name, :value, :source, :overridden, :confirmed_at]
    ]
  end

  # Additional action for confirming policy values
  def confirm?
    update?
  end

  # Additional action for re-validation
  def validate?
    belongs_to_organization? && record.in_review?
  end

  # Additional action for completing submission
  def complete?
    belongs_to_organization? && record.validated?
  end

  private

  # Check if the submission belongs to the user's current organization
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
      # Only return submissions for the current account's organization
      org = account_user.account.organization
      return scope.none if org.nil?

      scope.where(organization: org)
    end
  end
end
