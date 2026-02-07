# frozen_string_literal: true

# Client model for tracking natural persons, legal entities, and trusts.
# Part of the CRM for Monaco real estate AML/CFT compliance.
#
# Client types (AMSF terminology):
# - NATURAL_PERSON (Personne Physique): Natural person
# - LEGAL_ENTITY (Personne Morale): Legal entity (company)
# - TRUST (Trust): Trust structure
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

  validates :legal_person_type_other, presence: true, if: -> { legal_entity? && legal_person_type == "OTHER" }

  validates :vasp_type, presence: true, if: :is_vasp?
  validates :vasp_type, inclusion: { in: VASP_TYPES }, allow_blank: true
  validates :vasp_other_service_type, presence: true, if: -> { is_vasp? && vasp_type == "OTHER" }

  # Trust-specific validations
  validates :trustee_name, presence: true, if: :trust?
  validates :trustee_nationality, presence: true, if: :trust?
  validates :trustee_country, presence: true, if: :trust?

  validates :risk_level, inclusion: { in: RISK_LEVELS }, allow_blank: true
  validates :rejection_reason, inclusion: { in: REJECTION_REASONS }, allow_blank: true
  validates :residence_status, inclusion: { in: RESIDENCE_STATUSES }, allow_blank: true
  validates :incorporation_country,
    format: { with: /\A[A-Z]{2}\z/, message: "must be ISO 3166-1 alpha-2 format" },
    allow_blank: true

  validates :introducer_country,
    presence: true,
    format: { with: /\A[A-Z]{2}\z/, message: "must be ISO 3166-1 alpha-2 format" },
    if: :introduced_by_third_party?

  # Third-party CDD validations
  validates :third_party_cdd_type,
    presence: true,
    inclusion: { in: THIRD_PARTY_CDD_TYPES },
    if: :third_party_cdd?

  validates :third_party_cdd_country,
    presence: true,
    format: { with: /\A[A-Z]{2}\z/, message: "must be ISO 3166-1 alpha-2 format" },
    if: -> { third_party_cdd? && third_party_cdd_type == "FOREIGN" }

  # AMSF Data Capture validations
  validates :due_diligence_level, inclusion: { in: DUE_DILIGENCE_LEVELS }, allow_blank: true
  validates :simplified_dd_reason, presence: true, if: -> { due_diligence_level == "SIMPLIFIED" }
  validates :relationship_end_reason, inclusion: { in: RELATIONSHIP_END_REASONS }, allow_blank: true
  validates :professional_category, inclusion: { in: PROFESSIONAL_CATEGORIES }, allow_blank: true

  # === Callbacks ===
  before_save :clear_legal_person_type_other_if_not_needed
  before_save :clear_pep_type_if_not_pep
  before_save :clear_vasp_type_if_not_vasp
  before_save :clear_third_party_cdd_fields_if_not_used

  # === Scopes ===

  # Client type scopes
  scope :natural_persons, -> { where(client_type: "NATURAL_PERSON") }
  scope :legal_entities, -> { where(client_type: "LEGAL_ENTITY") }
  scope :trusts, -> { where(client_type: "TRUST") }
  scope :professional_trustees, -> { trusts.where(is_professional_trustee: true) }

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

  # Introducer scopes
  scope :introduced, -> { where(introduced_by_third_party: true) }

  # Third-party CDD scopes
  scope :with_third_party_cdd, -> { where(third_party_cdd: true) }
  scope :with_local_third_party_cdd, -> { where(third_party_cdd: true, third_party_cdd_type: "LOCAL") }
  scope :with_foreign_third_party_cdd, -> { where(third_party_cdd: true, third_party_cdd_type: "FOREIGN") }

  # Organization scope (for policy/controller use)
  scope :for_organization, ->(org) { where(organization: org) }

  # Search scope - uses sanitize_sql_like to escape LIKE special characters (%, _, \)
  scope :search, ->(query) {
    return all if query.blank?

    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  # === Instance Methods ===

  def natural_person?
    client_type == "NATURAL_PERSON"
  end

  def legal_entity?
    client_type == "LEGAL_ENTITY"
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
    client_type.humanize
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

  # Clear legal_person_type_other when legal_person_type is not OTHER
  def clear_legal_person_type_other_if_not_needed
    self.legal_person_type_other = nil if legal_person_type != "OTHER"
  end

  # Clear pep_type when is_pep is set to false to maintain data consistency
  def clear_pep_type_if_not_pep
    self.pep_type = nil unless is_pep?
  end

  # Clear vasp_type and vasp_other_service_type when is_vasp is false or vasp_type changes from OTHER
  def clear_vasp_type_if_not_vasp
    unless is_vasp?
      self.vasp_type = nil
      self.vasp_other_service_type = nil
    end
    self.vasp_other_service_type = nil if vasp_type != "OTHER"
  end

  # Clear third-party CDD fields when third_party_cdd is set to false
  def clear_third_party_cdd_fields_if_not_used
    unless third_party_cdd?
      self.third_party_cdd_type = nil
      self.third_party_cdd_country = nil
    end
  end
end
