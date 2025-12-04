# frozen_string_literal: true

# Transaction model for tracking real estate transactions.
# Part of the CRM for Monaco real estate AML/CFT compliance.
#
# Transaction types (AMSF terminology):
# - PURCHASE: Property purchase
# - SALE: Property sale
# - RENTAL: Property rental
#
class Transaction < ApplicationRecord
  include AmsfConstants
  include Auditable
  include Discard::Model
  self.discard_column = :deleted_at

  # === Associations ===
  belongs_to :organization
  belongs_to :client
  has_many :str_reports, dependent: :nullify

  # === Validations ===
  validates :transaction_date, presence: true
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }

  # Optional field validations
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_blank: true
  validates :agency_role, inclusion: { in: AGENCY_ROLES }, allow_blank: true
  validates :purchase_purpose, inclusion: { in: PURCHASE_PURPOSES }, allow_blank: true
  validates :direction, inclusion: { in: TRANSACTION_DIRECTIONS }, allow_blank: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  # Ensure client belongs to the same organization
  validate :client_belongs_to_organization

  # === Scopes ===

  # Transaction type scopes
  scope :purchases, -> { where(transaction_type: "PURCHASE") }
  scope :sales, -> { where(transaction_type: "SALE") }
  scope :rentals, -> { where(transaction_type: "RENTAL") }

  # Year filtering
  scope :for_year, ->(year) {
    where(transaction_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
  }

  # Payment method scopes
  scope :with_cash, -> { where(payment_method: %w[CASH MIXED]).where.not(cash_amount: [nil, 0]) }
  scope :by_payment_method, ->(method) { where(payment_method: method) }

  # Direction scopes (BY client vs WITH client as agent)
  scope :by_client, -> { where(direction: "BY_CLIENT") }
  scope :with_client, -> { where(direction: "WITH_CLIENT") }

  # Ordering
  scope :recent, -> { order(transaction_date: :desc) }

  # Organization scope (for policy/controller use)
  scope :for_organization, ->(org) { where(organization: org) }

  # Search scope - uses sanitize_sql_like to escape LIKE special characters (%, _, \)
  scope :search, ->(query) {
    return all if query.blank?

    sanitized = sanitize_sql_like(query)
    where("reference ILIKE ? OR notes ILIKE ?", "%#{sanitized}%", "%#{sanitized}%")
  }

  # === Instance Methods ===

  def purchase?
    transaction_type == "PURCHASE"
  end

  def sale?
    transaction_type == "SALE"
  end

  def rental?
    transaction_type == "RENTAL"
  end

  def has_cash?
    cash_amount.present? && cash_amount > 0
  end

  # For display purposes
  def transaction_type_label
    case transaction_type
    when "PURCHASE" then "Purchase"
    when "SALE" then "Sale"
    when "RENTAL" then "Rental"
    else transaction_type
    end
  end

  def payment_method_label
    case payment_method
    when "WIRE" then "Bank Transfer"
    when "CASH" then "Cash"
    when "CHECK" then "Check"
    when "CRYPTO" then "Cryptocurrency"
    when "MIXED" then "Mixed Payment"
    else payment_method
    end
  end

  def agency_role_label
    case agency_role
    when "BUYER_AGENT" then "Buyer's Agent"
    when "SELLER_AGENT" then "Seller's Agent"
    when "DUAL_AGENT" then "Dual Agent"
    else agency_role
    end
  end

  def purchase_purpose_label
    case purchase_purpose
    when "RESIDENCE" then "Primary Residence"
    when "INVESTMENT" then "Investment"
    else purchase_purpose
    end
  end

  private

  def client_belongs_to_organization
    return unless client.present? && organization.present?
    return if client.organization_id == organization_id

    errors.add(:client, "must belong to the same organization")
  end
end
