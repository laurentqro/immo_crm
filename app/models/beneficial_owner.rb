# frozen_string_literal: true

# Beneficial owner model for tracking ownership of legal entities and trusts.
# Required by Monaco AMSF AML/CFT regulations for PM and TRUST clients.
#
# Beneficial owners must be natural persons who:
# - Own >25% of shares/voting rights (direct ownership)
# - Control the entity through other means (indirect)
# - Act as legal representative (representative)
#
# HNWI/UHNWI Classification:
# - HNWI (High Net Worth Individual): net_worth_eur > 5,000,000 EUR
# - UHNWI (Ultra High Net Worth Individual): net_worth_eur > 50,000,000 EUR
# These are derived from net_worth_eur to guarantee UHNWI ⊂ HNWI (AMSF requirement).
#
class BeneficialOwner < ApplicationRecord
  include AmsfConstants
  include Auditable

  # HNWI/UHNWI thresholds in EUR (from AMSF gap analysis)
  HNWI_THRESHOLD = 5_000_000
  UHNWI_THRESHOLD = 50_000_000

  # === Associations ===
  belongs_to :client

  # === Validations ===
  validates :name, presence: true

  # Ownership percentage between 0-100 (if provided)
  validates :ownership_percentage,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    },
    allow_nil: true

  validates :control_type, inclusion: { in: CONTROL_TYPES }, allow_blank: true

  # PEP validation (same as Client)
  validates :pep_type, presence: true, if: :is_pep?
  validates :pep_type, inclusion: { in: PEP_TYPES }, allow_blank: true

  # Client type validation - beneficial owners only for PM/TRUST
  validate :client_must_be_legal_entity_or_trust

  # === Callbacks ===
  before_save :clear_pep_type_if_not_pep

  # === Scopes ===
  scope :peps, -> { where(is_pep: true) }
  scope :for_client, ->(client) { where(client: client) }
  scope :direct, -> { where(control_type: "DIRECT") }
  scope :indirect, -> { where(control_type: "INDIRECT") }
  scope :representatives, -> { where(control_type: "REPRESENTATIVE") }
  scope :with_significant_control, -> { where("ownership_percentage >= ?", 25) }
  # HNWI/UHNWI scopes derived from net_worth_eur
  # This guarantees UHNWI ⊂ HNWI since anyone >50M is also >5M
  scope :hnwis, -> { where("net_worth_eur > ?", HNWI_THRESHOLD) }
  scope :uhnwis, -> { where("net_worth_eur > ?", UHNWI_THRESHOLD) }

  # === Instance Methods ===

  def ownership_percentage_display
    return nil unless ownership_percentage
    "#{ownership_percentage}%"
  end

  def control_type_label
    case control_type
    when "DIRECT" then "Direct Ownership"
    when "INDIRECT" then "Indirect Control"
    when "REPRESENTATIVE" then "Legal Representative"
    else control_type
    end
  end

  # HNWI status derived from net_worth_eur
  def hnwi?
    net_worth_eur.present? && net_worth_eur > HNWI_THRESHOLD
  end

  # UHNWI status derived from net_worth_eur
  def uhnwi?
    net_worth_eur.present? && net_worth_eur > UHNWI_THRESHOLD
  end

  # Delegate organization access through client
  delegate :organization, to: :client, allow_nil: true

  private

  def client_must_be_legal_entity_or_trust
    return unless client

    unless client.can_have_beneficial_owners?
      errors.add(:client, "must be a legal entity (PM) or trust")
    end
  end

  # Clear pep_type when is_pep is set to false to maintain data consistency
  def clear_pep_type_if_not_pep
    self.pep_type = nil unless is_pep?
  end
end
