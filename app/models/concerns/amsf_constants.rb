# frozen_string_literal: true

# AMSF (Monaco AML/CFT) enumeration values and constants
# These map to XBRL taxonomy elements for annual submission
module AmsfConstants
  extend ActiveSupport::Concern

  # Client types (Personne Physique, Personne Morale, Trust)
  CLIENT_TYPES = %w[PP PM TRUST].freeze

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

  # Suspicious Transaction Report reasons
  STR_REASONS = %w[CASH PEP UNUSUAL_PATTERN OTHER].freeze

  # Client rejection reasons
  REJECTION_REASONS = %w[AML_CFT OTHER].freeze

  # Setting categories for organization configuration
  SETTING_CATEGORIES = %w[entity_info kyc compliance training].freeze

  # Setting value types for type casting
  SETTING_TYPES = %w[boolean integer decimal string date enum].freeze

  # Submission workflow statuses
  SUBMISSION_STATUSES = %w[draft in_review validated completed].freeze

  # Source of submission values
  SUBMISSION_VALUE_SOURCES = %w[calculated from_settings manual].freeze

  # Audit log action types
  AUDIT_ACTIONS = %w[login logout login_failed create update delete download].freeze
end
