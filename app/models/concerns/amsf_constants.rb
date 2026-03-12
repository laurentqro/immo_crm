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

  # Client types (Personne Physique, Personne Morale)
  CLIENT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY].freeze

  # Transaction types
  TRANSACTION_TYPES = %w[PURCHASE SALE RENTAL].freeze

  # Payment methods
  PAYMENT_METHODS = %w[WIRE CASH CHECK CRYPTO MIXED].freeze

  # Agency roles in transaction
  AGENCY_ROLES = %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].freeze

  # Risk assessment levels
  RISK_LEVELS = %w[LOW MEDIUM HIGH].freeze

  # Net worth ranges (AMSF thresholds: HNWI >5M EUR, UHNWI >50M EUR)
  NET_WORTH_RANGES = %w[UNDER_5M 5M_TO_50M OVER_50M].freeze

  # Politically Exposed Person types
  PEP_TYPES = %w[DOMESTIC FOREIGN INTL_ORG].freeze

  # Beneficial owner control types
  CONTROL_TYPES = %w[DIRECT INDIRECT REPRESENTATIVE].freeze

  # Virtual Asset Service Provider types
  VASP_TYPES = %w[EXCHANGE CUSTODIAN ICO TRANSFER DEFI NFT PAYMENT FUND_MANAGEMENT OTHER].freeze

  # AMSF named VASP categories (XBRL has dedicated fields for these three)
  # Everything else maps to the AMSF "other" bucket in survey fields.
  AMSF_NAMED_VASP_TYPES = %w[EXCHANGE CUSTODIAN ICO].freeze

  # Human-readable labels for VASP types
  VASP_TYPE_LABELS = {
    "EXCHANGE" => "Virtual currency exchange",
    "CUSTODIAN" => "Custodian wallet provider",
    "ICO" => "Token offering services (ICO/STO)",
    "TRANSFER" => "Virtual asset transfer/remittance",
    "DEFI" => "DeFi services (lending, staking, yield)",
    "NFT" => "NFT marketplace/services",
    "PAYMENT" => "Crypto payment processing",
    "FUND_MANAGEMENT" => "Crypto asset/fund management",
    "OTHER" => "Other"
  }.freeze

  # Legal entity types (Monaco corporate forms + AMSF taxonomy types)
  LEGAL_ENTITY_TYPES = %w[
    SCI SARL SAM SNC SA SCS SCA SCP
    GIE EI
    FOUNDATION ASSOCIATION
    OTHER_CIVIL OTHER_COMMERCIAL
    STATE_DOMAIN
    TRUST
    OTHER
    UNKNOWN
  ].freeze

  # Mapping from app legal_entity_type to XBRL dimension member suffix.
  # The gem prefixes these with "sdl" to produce members like sdlSAM, sdlLA1, etc.
  # Members defined in CountryTableaLE in the _def.xml taxonomy.
  LEGAL_ENTITY_TYPE_TO_XBRL = {
    "SAM" => "SAM",
    "SARL" => "SARL",
    "SCI" => "SCI",
    "SCP" => "SCP",
    "SNC" => "SNC",
    "SCS" => "SCS",
    "SCA" => "SCA",
    "SA" => "SAM",
    "EI" => "SP",
    "GIE" => "GIE",
    "ASSOCIATION" => "MAENTITÉS",
    "FOUNDATION" => "MFENTITÉS",
    "TRUST" => "LA1",
    "OTHER_CIVIL" => "SCAUTRE",
    "OTHER_COMMERCIAL" => "SCAUTRE",
    "STATE_DOMAIN" => "DP",
    "OTHER" => "LA2",
    "UNKNOWN" => "UNKNOWNLE"
  }.freeze

  # Human-readable labels for legal entity types
  LEGAL_ENTITY_TYPE_LABELS = {
    "SCI" => "Property Investment Partnership (SCI)",
    "SARL" => "Limited Liability Company (SARL)",
    "SAM" => "Joint Stock Company (SAM)",
    "SNC" => "Commercial Partnership (SNC)",
    "SA" => "Société Anonyme (SA)",
    "SCS" => "Limited Partnership (SCS)",
    "SCA" => "Limited Partnership with Shares (SCA)",
    "SCP" => "Special Civil-law Partnership (SCP)",
    "GIE" => "Economic Interest Group (GIE)",
    "EI" => "Sole Person (EI)",
    "FOUNDATION" => "Monegasque Foundation",
    "ASSOCIATION" => "Monegasque Association",
    "OTHER_CIVIL" => "Other Civil Companies",
    "OTHER_COMMERCIAL" => "Other Commercial Companies",
    "STATE_DOMAIN" => "Private Domain of the Monegasque State",
    "TRUST" => "Trust",
    "OTHER" => "Other Legal Arrangements",
    "UNKNOWN" => "Unknown"
  }.freeze

  # Standard commercial/civil forms have dedicated AMSF sections.
  # Trusts have their own dedicated section (a1801-a1809).
  # Everything else is "other legal constructions" for field a11006.
  AMSF_STANDARD_LEGAL_FORMS = %w[SCI SARL SAM SNC SA SCS SCA SCP EI TRUST].freeze

  # Purchase purpose
  PURCHASE_PURPOSES = %w[RESIDENCE INVESTMENT].freeze

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
  SUBMISSION_STATUSES = %w[draft in_review completed].freeze

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

  # Third-Party CDD Types (local vs foreign providers)
  THIRD_PARTY_CDD_TYPES = %w[LOCAL FOREIGN].freeze

  # AMSF High-Risk Business Sectors (Q81-Q109)
  # Used to classify Monegasque clients by sector for the annual survey.
  # BUSINESS_SECTORS is derived from labels to keep a single source of truth.
  BUSINESS_SECTOR_LABELS = {
    "LEGAL_SERVICES" => "Lawyers / Legal professionals",
    "ACCOUNTING" => "Auditors / Accountants",
    "NOMINEE_SHAREHOLDER" => "Nominee shareholders / directors",
    "BEARER_INSTRUMENTS" => "Bearer shares / instruments",
    "REAL_ESTATE" => "Real estate agents",
    "NMPPP" => "Dealers in precious metals & stones (NMPPP)",
    "TCSP" => "Trust & company service providers",
    "MULTI_FAMILY_OFFICE" => "Multi-Family Office",
    "SINGLE_FAMILY_OFFICE" => "Single-Family Office",
    "COMPLEX_STRUCTURES" => "Complex ownership structures",
    "CASH_INTENSIVE" => "Cash-intensive businesses",
    "PREPAID_CARDS" => "Prepaid / anonymous cards",
    "ART_ANTIQUITIES" => "Art & antiquities",
    "IMPORT_EXPORT" => "Import / Export",
    "HIGH_VALUE_GOODS" => "High-value goods dealers",
    "NPO" => "Non-profit organisations (OBNL)",
    "GAMBLING" => "Casino / Gambling",
    "CONSTRUCTION" => "Construction / Property development",
    "EXTRACTIVE" => "Extractive industries",
    "DEFENSE_WEAPONS" => "Defence / Weapons",
    "YACHTING" => "Yachting / Pleasure navigation",
    "SPORTS_AGENTS" => "Sports agents / intermediaries",
    "FUND_MANAGEMENT" => "Fund management",
    "HOLDING_COMPANY" => "Holding companies",
    "AUCTIONEERS" => "Auctioneers",
    "CAR_DEALERS" => "Motor vehicle dealers",
    "GOVERNMENT" => "Government / Public sector",
    "AIRCRAFT_JETS" => "Aircraft sales / Private jet charter",
    "TRANSPORT" => "Transport"
  }.freeze

  BUSINESS_SECTORS = BUSINESS_SECTOR_LABELS.keys.freeze

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
