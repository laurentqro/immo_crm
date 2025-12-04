# frozen_string_literal: true

# Organization extends Jumpstart Pro Account with AMSF-specific fields.
# Each Account has one Organization that stores Monaco business registry info.
#
# SOFT DELETE STRATEGY:
# Organizations are NOT soft-deleted. They are immutable once created because:
# 1. Each Account has exactly one Organization (1:1 relationship)
# 2. Organizations are the root entity for all compliance data
# 3. Audit logs reference organizations and must be retained for 5 years
# 4. Deleting an organization would orphan clients, transactions, and submissions
#
# If an organization needs to be "deactivated", use the Account's status instead.
# The OrganizationPolicy#destroy? method returns false to enforce this rule.
class Organization < ApplicationRecord
  include AmsfConstants
  include Auditable

  belongs_to :account

  # CRM associations
  has_many :clients, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :str_reports, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :settings, dependent: :destroy
  has_many :managed_properties, dependent: :destroy
  has_many :trainings, dependent: :destroy

  has_many :submissions, dependent: :destroy

  validates :name, presence: true, length: {maximum: 255}
  # RCI (Répertoire du Commerce et de l'Industrie) number validation.
  # Format kept intentionally permissive - Monaco RCI formats vary across business types.
  # Alphanumeric constraint prevents special characters while allowing flexibility.
  validates :rci_number, presence: true, uniqueness: true,
    format: {with: /\A[A-Za-z0-9]+\z/, message: "must be alphanumeric"},
    length: {minimum: 3, maximum: 20}
  validates :country, length: {is: 2}, allow_blank: true

  # Scopes for future use
  scope :by_country, ->(country) { where(country: country) }
end
