# Data Model: Immo CRM MVP

**Date**: 2025-11-30
**Status**: Complete

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           JUMPSTART PRO                                  │
│  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐            │
│  │   Account   │──────<│    User     │       │    Team     │            │
│  └─────────────┘       └─────────────┘       └─────────────┘            │
└────────┬────────────────────────────────────────────────────────────────┘
         │ has_one
         ▼
┌─────────────────┐
│  Organization   │
│                 │
│ - name          │
│ - rci_number    │
│ - country       │
└─────────────────┘
         │
    ┌────┴────┬─────────────┬─────────────┬─────────────┐
    │         │             │             │             │
    ▼         ▼             ▼             ▼             ▼
┌────────┐ ┌────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Client │ │Setting │ │Submission│ │STRReport │ │ AuditLog │
└────────┘ └────────┘ └──────────┘ └──────────┘ └──────────┘
    │                       │
    ├──────────┐           ▼
    │          │     ┌───────────────┐
    ▼          ▼     │SubmissionValue│
┌──────────┐ ┌───────────┐ └───────────────┘
│Beneficial│ │Transaction│
│  Owner   │ │           │
└──────────┘ └───────────┘
```

---

## Entities

### 1. Organization

**Purpose**: Extends Jumpstart Pro Account with AMSF-specific fields.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| account_id | bigint | FK, unique, not null | Links to Jumpstart Account |
| name | string | not null | Company/agency name |
| rci_number | string | not null, unique | Monaco business registry number |
| country | string | default: 'MC' | ISO 3166-1 alpha-2 |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Associations**:
- `belongs_to :account`
- `has_many :clients`
- `has_many :transactions`
- `has_many :submissions`
- `has_many :str_reports`
- `has_many :settings`
- `has_many :audit_logs`

**Validations**:
- `name`: presence, length 1-255
- `rci_number`: presence, uniqueness, format (alphanumeric)

---

### 2. Client

**Purpose**: Track natural persons, legal entities, and trusts for CRM and compliance.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| organization_id | bigint | FK, not null | |
| name | string | not null | |
| client_type | string | not null | PP, PM, TRUST |
| nationality | string | | ISO 3166-1 alpha-2 |
| residence_country | string | | ISO 3166-1 alpha-2 |
| is_pep | boolean | default: false | Politically Exposed Person |
| pep_type | string | | DOMESTIC, FOREIGN, INTL_ORG |
| risk_level | string | | LOW, MEDIUM, HIGH |
| is_vasp | boolean | default: false | Virtual Asset Service Provider |
| vasp_type | string | | CUSTODIAN, EXCHANGE, ICO, OTHER |
| legal_person_type | string | | SCI, SARL, SAM, SNC, SA, OTHER (PM only) |
| business_sector | string | | Industry classification |
| became_client_at | datetime | | When relationship started |
| relationship_ended_at | datetime | | When relationship ended (for retention calc) |
| rejection_reason | string | | AML_CFT, OTHER |
| notes | text | | Free-form notes |
| deleted_at | datetime | | Soft delete (Discard) |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Associations**:
- `belongs_to :organization`
- `has_many :beneficial_owners, dependent: :destroy`
- `has_many :transactions`
- `has_many :str_reports`

**Validations**:
- `name`: presence
- `client_type`: presence, inclusion in CLIENT_TYPES
- `pep_type`: inclusion in PEP_TYPES (if is_pep)
- `legal_person_type`: presence if client_type == 'PM'

**Scopes**:
- `natural_persons` → where(client_type: 'PP')
- `legal_entities` → where(client_type: 'PM')
- `trusts` → where(client_type: 'TRUST')
- `peps` → where(is_pep: true)
- `high_risk` → where(risk_level: 'HIGH')

---

### 3. BeneficialOwner

**Purpose**: Track beneficial owners for legal entities (PM, TRUST clients).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| client_id | bigint | FK, not null | Parent legal entity |
| name | string | not null | |
| nationality | string | | ISO 3166-1 alpha-2 |
| residence_country | string | | ISO 3166-1 alpha-2 |
| ownership_pct | decimal(5,2) | | 0.00 - 100.00 |
| control_type | string | | DIRECT, INDIRECT, REPRESENTATIVE |
| is_pep | boolean | default: false | |
| pep_type | string | | DOMESTIC, FOREIGN, INTL_ORG |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Associations**:
- `belongs_to :client`

**Validations**:
- `name`: presence
- `ownership_pct`: numericality 0-100 (if present)
- `control_type`: inclusion in CONTROL_TYPES (if present)
- Parent client must be PM or TRUST

---

### 4. Transaction

**Purpose**: Record real estate transactions (purchases, sales, rentals).

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| organization_id | bigint | FK, not null | |
| client_id | bigint | FK, not null | |
| reference | string | | User's reference number |
| transaction_date | date | not null | |
| transaction_type | string | not null | PURCHASE, SALE, RENTAL |
| transaction_value | decimal(15,2) | | Total value in EUR |
| commission_amount | decimal(15,2) | | Agency commission |
| property_country | string | default: 'MC' | ISO 3166-1 alpha-2 |
| payment_method | string | | WIRE, CASH, CHECK, CRYPTO, MIXED |
| cash_amount | decimal(15,2) | | Cash portion if CASH/MIXED |
| agency_role | string | | BUYER_AGENT, SELLER_AGENT, DUAL_AGENT |
| purchase_purpose | string | | RESIDENCE, INVESTMENT (purchases only) |
| notes | text | | |
| deleted_at | datetime | | Soft delete |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Associations**:
- `belongs_to :organization`
- `belongs_to :client`
- `has_many :str_reports`

**Validations**:
- `transaction_date`: presence
- `transaction_type`: presence, inclusion in TRANSACTION_TYPES
- `payment_method`: inclusion in PAYMENT_METHODS (if present)
- `cash_amount`: required if payment_method in [CASH, MIXED]
- `purchase_purpose`: required if transaction_type == 'PURCHASE'

**Scopes**:
- `purchases` → where(transaction_type: 'PURCHASE')
- `sales` → where(transaction_type: 'SALE')
- `rentals` → where(transaction_type: 'RENTAL')
- `for_year(year)` → where(transaction_date: year_range)
- `cash_transactions` → where(payment_method: ['CASH', 'MIXED'])

---

### 5. STRReport

**Purpose**: Document Suspicious Transaction Reports filed with authorities.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| organization_id | bigint | FK, not null | |
| client_id | bigint | FK, optional | Linked client (if applicable) |
| transaction_id | bigint | FK, optional | Linked transaction (if applicable) |
| report_date | date | not null | When STR was filed |
| reason | string | not null | CASH, PEP, UNUSUAL_PATTERN, OTHER |
| notes | text | | Details |
| deleted_at | datetime | | Soft delete |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Associations**:
- `belongs_to :organization`
- `belongs_to :client, optional: true`
- `belongs_to :transaction, optional: true`

**Validations**:
- `report_date`: presence
- `reason`: presence, inclusion in STR_REASONS

---

### 6. Setting

**Purpose**: Store organization settings that map to XBRL elements.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| organization_id | bigint | FK, not null | |
| key | string | not null | e.g., 'edd_for_peps' |
| value | string | | Stored as string, cast by type |
| value_type | string | not null | boolean, integer, decimal, string, date, enum |
| xbrl_element | string | | Maps to XBRL taxonomy e.g., 'a4101' |
| category | string | not null | entity_info, kyc, compliance, training |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Indexes**:
- Unique on `[organization_id, key]`

**Associations**:
- `belongs_to :organization`

**Validations**:
- `key`: presence, uniqueness scoped to organization
- `value_type`: presence, inclusion in TYPES
- `category`: presence, inclusion in SETTING_CATEGORIES

**Methods**:
- `typed_value` → returns value cast to appropriate Ruby type

---

### 7. Submission

**Purpose**: Annual AMSF submission with status tracking.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| organization_id | bigint | FK, not null | |
| year | integer | not null | Reporting year (e.g., 2025) |
| taxonomy_version | string | default: '2025' | AMSF taxonomy version |
| status | string | default: 'draft' | draft, in_review, validated, completed |
| started_at | datetime | | When user started submission |
| validated_at | datetime | | When validation passed |
| completed_at | datetime | | When XBRL downloaded |
| downloaded_unvalidated | boolean | default: false | If downloaded without validation |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Indexes**:
- Unique on `[organization_id, year]` (only one draft per year)

**Associations**:
- `belongs_to :organization`
- `has_many :submission_values, dependent: :destroy`

**Validations**:
- `year`: presence, numericality (reasonable range)
- `status`: inclusion in SUBMISSION_STATUSES

**State Machine** (AASM or manual):
```
draft → in_review → validated → completed
                 ↘ (if validation fails) → draft
```

---

### 8. SubmissionValue

**Purpose**: Snapshot of individual XBRL element values for a submission.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| submission_id | bigint | FK, not null | |
| element_name | string | not null | XBRL element e.g., 'a1101' |
| value | string | | Value as string |
| source | string | not null | calculated, from_settings, manual |
| overridden | boolean | default: false | User changed calculated value |
| confirmed_at | datetime | | When user reviewed this value |
| created_at | datetime | not null | |
| updated_at | datetime | not null | |

**Indexes**:
- Unique on `[submission_id, element_name]`

**Associations**:
- `belongs_to :submission`

**Validations**:
- `element_name`: presence
- `source`: presence, inclusion in SUBMISSION_VALUE_SOURCES

---

### 9. AuditLog

**Purpose**: Compliance audit trail for authentication and data changes.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | bigint | PK, auto | |
| organization_id | bigint | FK, optional | Null for auth events before login |
| user_id | bigint | FK, optional | Null for system events |
| action | string | not null | login, logout, create, update, delete, download |
| auditable_type | string | | Polymorphic type |
| auditable_id | bigint | | Polymorphic ID |
| metadata | jsonb | | IP, user agent, changed fields |
| created_at | datetime | not null | |

**Indexes**:
- Index on `[organization_id, created_at]`
- Index on `[auditable_type, auditable_id]`

**Associations**:
- `belongs_to :organization, optional: true`
- `belongs_to :user, optional: true`
- `belongs_to :auditable, polymorphic: true, optional: true`

**Validations**:
- `action`: presence

---

## Enums and Constants

```ruby
# app/models/concerns/amsf_constants.rb
module AmsfConstants
  extend ActiveSupport::Concern

  CLIENT_TYPES = %w[PP PM TRUST].freeze
  TRANSACTION_TYPES = %w[PURCHASE SALE RENTAL].freeze
  PAYMENT_METHODS = %w[WIRE CASH CHECK CRYPTO MIXED].freeze
  AGENCY_ROLES = %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].freeze
  RISK_LEVELS = %w[LOW MEDIUM HIGH].freeze
  PEP_TYPES = %w[DOMESTIC FOREIGN INTL_ORG].freeze
  CONTROL_TYPES = %w[DIRECT INDIRECT REPRESENTATIVE].freeze
  VASP_TYPES = %w[CUSTODIAN EXCHANGE ICO OTHER].freeze
  LEGAL_PERSON_TYPES = %w[SCI SARL SAM SNC SA OTHER].freeze
  PURCHASE_PURPOSES = %w[RESIDENCE INVESTMENT].freeze
  STR_REASONS = %w[CASH PEP UNUSUAL_PATTERN OTHER].freeze
  REJECTION_REASONS = %w[AML_CFT OTHER].freeze
  SETTING_CATEGORIES = %w[entity_info kyc compliance training].freeze
  SETTING_TYPES = %w[boolean integer decimal string date enum].freeze
  SUBMISSION_STATUSES = %w[draft in_review validated completed].freeze
  SUBMISSION_VALUE_SOURCES = %w[calculated from_settings manual].freeze
  AUDIT_ACTIONS = %w[login logout login_failed create update delete download].freeze
end
```

---

## Data Retention Rules

| Entity | Retention | Trigger | Hard Delete |
|--------|-----------|---------|-------------|
| Client | 5 years | After `relationship_ended_at` | Background job |
| BeneficialOwner | With parent | When parent Client deleted | Cascade |
| Transaction | 5 years | After `relationship_ended_at` on Client | Background job |
| STRReport | 5 years | After `relationship_ended_at` on Client | Background job |
| Submission | Indefinite | Never | Never |
| SubmissionValue | With parent | When parent Submission deleted | Cascade |
| AuditLog | 5 years | After `created_at` | Background job |
| Setting | Indefinite | Never | Never |

---

## Migration Order

1. `create_organizations` - extends Account
2. `create_clients` - depends on Organization
3. `create_beneficial_owners` - depends on Client
4. `create_transactions` - depends on Organization, Client
5. `create_str_reports` - depends on Organization, Client, Transaction
6. `create_settings` - depends on Organization
7. `create_submissions` - depends on Organization
8. `create_submission_values` - depends on Submission
9. `create_audit_logs` - depends on Organization, User
