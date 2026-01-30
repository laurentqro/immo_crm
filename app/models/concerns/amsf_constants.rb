# frozen_string_literal: true

# AMSF (Monaco AML/CFT) enumeration values and constants.
# These map to XBRL taxonomy elements for the annual AML/CFT submission.
#
# Reference: Monaco AMSF Real Estate Professionals AML/CFT Survey
# Taxonomy: strix_Real_Estate_AML_CFT_survey_2025
# See: docs/strix_Real_Estate_AML_CFT_survey_2025.xsd for full schema
# See: Xbrl::Taxonomy for element metadata parsed from AMSF taxonomy
#
module AmsfConstants
  extend ActiveSupport::Concern

  # Client types (Personne Physique, Personne Morale, Trust)
  CLIENT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY TRUST].freeze

  # Transaction types
  TRANSACTION_TYPES = %w[PURCHASE SALE RENTAL].freeze

  # Payment methods
  PAYMENT_METHODS = %w[WIRE CASH CHECK CRYPTO MIXED].freeze

  # Agency roles in transaction
  AGENCY_ROLES = %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].freeze

  # Risk assessment levels
  RISK_LEVELS = %w[LOW MEDIUM HIGH].freeze

  # Politically Exposed Person types
  PEP_TYPES = %w[DOMESTIC FOREIGN INTL_ORG].freeze

  # Beneficial owner control types
  CONTROL_TYPES = %w[DIRECT INDIRECT REPRESENTATIVE].freeze

  # Virtual Asset Service Provider types
  VASP_TYPES = %w[CUSTODIAN EXCHANGE ICO OTHER].freeze

  # Legal entity types (Monaco corporate forms)
  LEGAL_PERSON_TYPES = %w[SCI SARL SAM SNC SA OTHER].freeze

  # Purchase purpose
  PURCHASE_PURPOSES = %w[RESIDENCE INVESTMENT].freeze

  # Client residence status
  RESIDENCE_STATUSES = %w[RESIDENT NON_RESIDENT].freeze

  # Transaction payment direction (who handles the funds)
  # BY_CLIENT: Client pays directly (e.g., buyer wires funds to seller's account)
  # WITH_CLIENT: Funds flow through the agency (e.g., client pays agency, agency disburses)
  TRANSACTION_DIRECTIONS = %w[BY_CLIENT WITH_CLIENT].freeze

  # Suspicious Transaction Report reasons
  STR_REASONS = %w[CASH PEP UNUSUAL_PATTERN OTHER].freeze

  # Client rejection reasons
  REJECTION_REASONS = %w[AML_CFT OTHER].freeze

  # Setting categories for organization configuration
  SETTING_CATEGORIES = %w[entity_info kyc compliance training].freeze

  # Setting value types for type casting
  SETTING_TYPES = %w[boolean integer decimal string date enum].freeze

  # Submission workflow statuses (simplified: draft -> completed)
  SUBMISSION_STATUSES = %w[draft completed].freeze

  # Source of submission values
  SUBMISSION_VALUE_SOURCES = %w[calculated from_settings manual].freeze

  # Due Diligence Levels (FR-001)
  DUE_DILIGENCE_LEVELS = %w[STANDARD SIMPLIFIED REINFORCED].freeze

  # Relationship End Reasons
  RELATIONSHIP_END_REASONS = %w[
    CLIENT_REQUEST
    AML_CONCERN
    INACTIVITY
    BUSINESS_DECISION
    OTHER
  ].freeze

  # Professional Categories (FR-002)
  PROFESSIONAL_CATEGORIES = %w[
    LEGAL
    ACCOUNTANT
    NOTARY
    REAL_ESTATE
    FINANCIAL
    OTHER
    NONE
  ].freeze

  # Property Types (FR-008)
  PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL LAND MIXED].freeze

  # Tenant Types (FR-006)
  TENANT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY].freeze

  # Training Types (FR-007)
  TRAINING_TYPES = %w[INITIAL REFRESHER SPECIALIZED].freeze

  # Training Topics
  TRAINING_TOPICS = %w[
    AML_BASICS
    PEP_SCREENING
    STR_FILING
    RISK_ASSESSMENT
    SANCTIONS
    KYC_PROCEDURES
    OTHER
  ].freeze

  # Training Providers
  TRAINING_PROVIDERS = %w[INTERNAL EXTERNAL AMSF ONLINE].freeze

  # Managed Property Types
  MANAGED_PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL].freeze

  # Year-over-year comparison threshold (FR-019)
  # Changes greater than this percentage require additional review
  SIGNIFICANCE_THRESHOLD = 25.0

  # Valid submission year range (AMSF established 2009, reasonable future)
  # Note: MIN set to 2009 when AMSF was established in Monaco
  MIN_SUBMISSION_YEAR = 2009
  MAX_SUBMISSION_YEAR = 2099

  # Note: Audit log action types are defined as a Rails enum in AuditLog model.
  # Use AuditLog.actions.keys to get the list of valid actions.
end
