# frozen_string_literal: true

# Client model for tracking natural persons, legal entities, and trusts.
# Part of the CRM for Monaco real estate AML/CFT compliance.
#
# Client types (AMSF terminology):
# - PP (Personne Physique): Natural person
# - PM (Personne Morale): Legal entity (company)
# - TRUST: Trust structure
#
class Client < ApplicationRecord
  include AmsfConstants
  include Auditable
  include Discard::Model
  self.discard_column = :deleted_at

  # === Associations ===
  belongs_to :organization
  has_many :beneficial_owners, dependent: :destroy
  has_many :transactions, dependent: :restrict_with_error
  has_many :str_reports, dependent: :nullify

  # === Validations ===
  validates :name, presence: true
  validates :client_type, presence: true, inclusion: { in: CLIENT_TYPES }

  # Conditional validations
  validates :legal_person_type, presence: true, if: :legal_entity?
  validates :legal_person_type, inclusion: { in: LEGAL_PERSON_TYPES }, allow_blank: true

  validates :pep_type, presence: true, if: :is_pep?
  validates :pep_type, inclusion: { in: PEP_TYPES }, allow_blank: true

  validates :vasp_type, presence: true, if: :is_vasp?
  validates :vasp_type, inclusion: { in: VASP_TYPES }, allow_blank: true

  validates :risk_level, inclusion: { in: RISK_LEVELS }, allow_blank: true
  validates :rejection_reason, inclusion: { in: REJECTION_REASONS }, allow_blank: true
  validates :residence_status, inclusion: { in: RESIDENCE_STATUSES }, allow_blank: true

  # === Callbacks ===
  before_save :clear_pep_type_if_not_pep
  before_save :clear_vasp_type_if_not_vasp

  # === Scopes ===

  # Client type scopes
  scope :natural_persons, -> { where(client_type: "PP") }
  scope :legal_entities, -> { where(client_type: "PM") }
  scope :trusts, -> { where(client_type: "TRUST") }

  # Risk/compliance scopes
  scope :peps, -> { where(is_pep: true) }
  scope :pep_related, -> { where(is_pep_related: true) }
  scope :pep_associated, -> { where(is_pep_associated: true) }
  scope :high_risk, -> { where(risk_level: "HIGH") }
  scope :vasps, -> { where(is_vasp: true) }

  # Residence scopes
  scope :residents, -> { where(residence_status: "RESIDENT") }
  scope :non_residents, -> { where(residence_status: "NON_RESIDENT") }

  # Relationship status scopes
  scope :active, -> { where(relationship_ended_at: nil) }
  scope :ended, -> { where.not(relationship_ended_at: nil) }

  # Organization scope (for policy/controller use)
  scope :for_organization, ->(org) { where(organization: org) }

  # Search scope - uses sanitize_sql_like to escape LIKE special characters (%, _, \)
  scope :search, ->(query) {
    return all if query.blank?

    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  # === Instance Methods ===

  def natural_person?
    client_type == "PP"
  end

  def legal_entity?
    client_type == "PM"
  end

  def trust?
    client_type == "TRUST"
  end

  # Legal entities and trusts can have beneficial owners
  def can_have_beneficial_owners?
    legal_entity? || trust?
  end

  def active?
    relationship_ended_at.nil?
  end

  def ended?
    relationship_ended_at.present?
  end

  # For display purposes
  def client_type_label
    case client_type
    when "PP" then "Natural Person"
    when "PM" then "Legal Entity"
    when "TRUST" then "Trust"
    else client_type
    end
  end

  def risk_badge_class
    case risk_level
    when "HIGH" then "bg-red-100 text-red-800"
    when "MEDIUM" then "bg-yellow-100 text-yellow-800"
    when "LOW" then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  private

  # Clear pep_type when is_pep is set to false to maintain data consistency
  def clear_pep_type_if_not_pep
    self.pep_type = nil unless is_pep?
  end

  # Clear vasp_type when is_vasp is set to false to maintain data consistency
  def clear_vasp_type_if_not_vasp
    self.vasp_type = nil unless is_vasp?
  end
end
