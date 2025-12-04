# frozen_string_literal: true

# ManagedProperty model for tracking property management contracts (gestion locative).
# This is a primary revenue source for Monaco real estate agencies.
#
# Used for:
# - Tracking managed properties for AMSF survey element a3804 (management revenue)
# - Tenant statistics (a1802TOLA series)
# - Activity flags (aACTIVEPS)
#
class ManagedProperty < ApplicationRecord
  include AmsfConstants

  # === Associations ===
  belongs_to :organization
  belongs_to :client  # landlord

  # === Validations ===
  validates :property_address, presence: true
  validates :management_start_date, presence: true
  validates :property_type, inclusion: { in: MANAGED_PROPERTY_TYPES }, allow_blank: true
  validates :tenant_type, inclusion: { in: TENANT_TYPES }, allow_blank: true
  validates :tenant_country, format: { with: /\A[A-Z]{2}\z/ }, allow_blank: true
  validates :monthly_rent, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :management_fee_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :management_fee_fixed, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  validate :client_belongs_to_organization
  validate :fee_structure_present

  # === Scopes ===
  scope :active, -> { where(management_end_date: nil) }

  scope :active_in_year, ->(year) {
    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)
    where("management_start_date <= ? AND (management_end_date IS NULL OR management_end_date >= ?)",
          year_end, year_start)
  }

  scope :for_organization, ->(org) { where(organization: org) }
  scope :residential, -> { where(property_type: "RESIDENTIAL") }
  scope :commercial, -> { where(property_type: "COMMERCIAL") }

  # === Instance Methods ===

  def active?
    management_end_date.nil?
  end

  def ended?
    management_end_date.present?
  end

  # Calculate monthly management fee
  def monthly_fee
    return management_fee_fixed if management_fee_fixed.present?
    return 0 unless monthly_rent.present? && management_fee_percent.present?

    (monthly_rent * management_fee_percent / 100).round(2)
  end

  # Calculate annual management revenue for this property
  def annual_revenue(year = Date.current.year)
    return 0 unless active_during_year?(year)

    months_active = months_active_in_year(year)
    monthly_fee * months_active
  end

  # Check if property was active during a given year
  def active_during_year?(year)
    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)

    management_start_date <= year_end &&
      (management_end_date.nil? || management_end_date >= year_start)
  end

  # Count months active in a year (for prorated revenue)
  def months_active_in_year(year)
    return 0 unless active_during_year?(year)

    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)

    effective_start = [management_start_date, year_start].max
    effective_end = management_end_date.present? ? [management_end_date, year_end].min : year_end

    # Calculate months (rounded)
    ((effective_end - effective_start).to_i / 30.0).ceil.clamp(1, 12)
  end

  private

  def client_belongs_to_organization
    return unless client.present? && organization.present?
    return if client.organization_id == organization_id

    errors.add(:client, "must belong to the same organization")
  end

  def fee_structure_present
    return if management_fee_percent.present? || management_fee_fixed.present?

    errors.add(:base, "Either percentage or fixed fee must be specified")
  end
end
