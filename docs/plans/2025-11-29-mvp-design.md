# [AppName] MVP Design Document

**Date:** November 29, 2025
**Updated:** November 30, 2025
**Status:** Draft - Pending Approval
**Author:** Laurent + Claude

---

## Executive Summary

**[AppName]** is a mini-CRM for Monaco real estate agents that makes annual AMSF AML/CFT compliance effortless.

**Core value proposition:**
- **Year-round:** Track clients, transactions, and beneficial owners in a simple CRM
- **Set once:** Configure compliance policies in settings (stable year-over-year)
- **At submission time:** Review auto-calculated aggregates, confirm policies, download XBRL

**Philosophy:** The web app is a useful CRM first, compliance tool second. Users get value all year from tracking their business. The annual AMSF submission becomes a 15-minute review, not a 2-week project.

**Target:** 2 weeks of manual work → 15 minutes with [AppName]

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [User Workflows](#2-user-workflows)
3. [Data Model](#3-data-model)
4. [Feature Specifications](#4-feature-specifications)
5. [Technical Architecture](#5-technical-architecture)
6. [XBRL Generation](#6-xbrl-generation)
7. [Validation Service](#7-validation-service)
8. [Infrastructure](#8-infrastructure)
9. [MVP Scope](#9-mvp-scope)
10. [Implementation Phases](#10-implementation-phases)
11. [Future: Excel Import](#11-future-excel-import)

---

## Clarifications

### Session 2025-11-30

- Q: What is the data retention policy for client and transaction records? → A: 5 years after relationship ends (regulatory minimum per AMSF AML/CFT requirements)
- Q: How should the system handle cross-tenant data access attempts? → A: Return 404 Not Found (hide resource existence for security)
- Q: How should concurrent submission access be handled? → A: Single active draft per year; any org user can continue it
- Q: What happens if the validation service is unavailable? → A: Allow download with prominent warning (unvalidated file)
- Q: What level of audit logging is required? → A: Auth events + CRUD operations on clients, transactions, submissions

---

## 1. Product Vision

### Problem

Monaco real estate agents must submit annual AMSF AML/CFT reports via the FT Solutions Strix portal. Currently:

- **180+ questions** to answer manually
- **2 weeks** of full-time work per submission
- **High error rate** from manual calculations
- **No tools exist** to simplify this process

### Solution: CRM-First Approach

[AppName] is a **mini-CRM that happens to generate XBRL**, not a compliance tool that happens to store data.

**Year-round (the CRM):**
1. **Clients** - Track natural persons, legal entities, trusts
2. **Beneficial Owners** - Record ownership structures for legal entities
3. **Transactions** - Log purchases, sales, rentals as they happen
4. **STR Reports** - Document suspicious activity reports

**Set once (Settings):**
5. **Entity Info** - Company name, RCI number, employee count
6. **Compliance Policies** - KYC procedures, EDD triggers, training frequency

**At submission time (Annual):**
7. **Submission Review** - View auto-calculated aggregates from CRM data
8. **Policy Confirmation** - Only answer questions that genuinely need re-answering
9. **XBRL Download** - Validated file ready for Strix upload

### Why CRM-First Wins

| Questionnaire-First | CRM-First |
|---------------------|-----------|
| Value only at deadline | Value all year |
| Bulk data entry = errors | Incremental entry = accuracy |
| Compliance chore | Business tool |
| 2-4 hours at submission | 15 minutes at submission |

### Future Vision

The MVP focuses on real estate AML/CFT compliance. Over time, [AppName] could expand:

- Full CRM features (deal pipeline, documents, calendar)
- Multi-industry compliance (yachting, banking, art dealers)
- Multi-jurisdiction (France, Luxembourg)

---

## 2. User Workflows

### 2.1 Onboarding (First-Time Setup)

```
Sign Up → Create Organization
              ↓
    ┌─────────────────────────────────┐
    │ Initial Setup Wizard            │
    │                                 │
    │ 1. Entity Info                  │
    │    - Company name               │
    │    - RCI number                 │
    │    - Employee count             │
    │                                 │
    │ 2. Compliance Policies          │
    │    - KYC procedures             │
    │    - EDD triggers               │
    │    - Training frequency         │
    │                                 │
    │ (These go into Settings,        │
    │  rarely need updating)          │
    └─────────────────────────────────┘
              ↓
         Dashboard
    "Start adding clients & transactions"
```

### 2.2 Year-Round Usage (The CRM)

```
Throughout the Year:
    ┌─────────────────────────────────┐
    │           Dashboard             │
    │                                 │
    │  Recent Transactions    [+ Add] │
    │  ─────────────────────────────  │
    │  Today   | Sale    | €1.2M     │
    │  Mar 15  | Purchase| €3.5M     │
    │  Mar 10  | Rental  | €24K/yr   │
    │                                 │
    │  Clients: 42        [View All] │
    │  Transactions: 28   [View All] │
    │  STRs This Year: 1             │
    └─────────────────────────────────┘
              │
              ↓
    Add transactions as deals close
    Add clients as relationships start
    Log STRs if suspicious activity
```

### 2.3 Annual Submission (15 Minutes)

```
Submission Deadline Approaching:
              ↓
    "Start 2025 Submission" button
              ↓
    ┌─────────────────────────────────┐
    │ Step 1: Review Aggregates       │
    │                                 │
    │ Calculated from your CRM data:  │
    │                                 │
    │ Clients:        42              │
    │   Natural:      30              │
    │   Legal:        10              │
    │   Trusts:        2              │
    │                                 │
    │ Transactions:   28              │
    │   Purchases:    12  (€15.2M)   │
    │   Sales:         8  (€9.8M)    │
    │   Rentals:       8  (€180K)    │
    │                                 │
    │ ✓ Looks correct    [Next →]    │
    └─────────────────────────────────┘
              ↓
    ┌─────────────────────────────────┐
    │ Step 2: Confirm Policies        │
    │                                 │
    │ Pre-filled from Settings:       │
    │                                 │
    │ ✓ EDD applied for PEPs          │
    │ ✓ EDD applied for high-risk     │
    │ ✓ Training conducted annually   │
    │                                 │
    │ 12 policy answers unchanged     │
    │                                 │
    │ [Confirm All]         [Next →] │
    └─────────────────────────────────┘
              ↓
    ┌─────────────────────────────────┐
    │ Step 3: Answer New Questions    │
    │                                 │
    │ These require fresh answers:    │
    │                                 │
    │ Did you reject any clients      │
    │ for AML/CFT reasons this year?  │
    │ [Yes ▼]  How many? [3    ]     │
    │                                 │
    │ Any changes to your AML/CFT     │
    │ procedures this year?           │
    │ [No ▼]                          │
    │                                 │
    │ (Only 3-5 questions typically)  │
    │                                 │
    │                       [Next →]  │
    └─────────────────────────────────┘
              ↓
    ┌─────────────────────────────────┐
    │ Step 4: Validate & Download     │
    │                                 │
    │ Running 275 validation rules... │
    │ ✅ All rules passed             │
    │                                 │
    │   ┌─────────────────────────┐   │
    │   │  📥 Download XBRL File  │   │
    │   └─────────────────────────┘   │
    │                                 │
    │ Upload to Strix portal to       │
    │ complete your submission.       │
    └─────────────────────────────────┘
```

### 2.4 Returning User (Year 2+)

Same as 2.3, but even faster:
- CRM data already populated from previous year
- Settings already configured
- Only need to add new transactions/clients from this year
- Submission is purely review + a few fresh questions

---

## 3. Data Model

### 3.1 Architecture Overview

The data model separates three concerns:

1. **CRM Data** (year-round) - Clients, transactions, beneficial owners, STRs
2. **Settings** (set once) - Entity info, compliance policies
3. **Submissions** (annual) - Snapshot of calculated values + fresh answers

```
┌─────────────────────────────────────────────────────────────────┐
│                        JUMPSTART PRO                            │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │     Account     │────<│      User       │                   │
│  └─────────────────┘     └─────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
                │
                │ has_one
                ↓
┌─────────────────────────────────────────────────────────────────┐
│                       ORGANIZATION                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Organization                                             │   │
│  │ - name, rci_number, country                              │   │
│  └─────────────────────────────────────────────────────────┘   │
│                │                                                │
│       ┌────────┴────────┬─────────────────┐                    │
│       ↓                 ↓                 ↓                    │
│  ┌─────────┐    ┌──────────────┐   ┌─────────────┐            │
│  │ Settings│    │   CRM Data   │   │ Submissions │            │
│  │(set once)│   │ (year-round) │   │  (annual)   │            │
│  └─────────┘    └──────────────┘   └─────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 CRM Data (Year-Round)

```
Organization
     │
     │ has_many
     ├────────────────────────────────────────┐
     ↓                                        ↓
┌─────────────────┐                  ┌─────────────────┐
│     Client      │                  │   STRReport     │
│                 │                  │                 │
│ - name          │                  │ - date          │
│ - client_type   │                  │ - reason        │
│ - nationality   │                  │ - client_id?    │
│ - residence     │                  │ - transaction_id│
│ - is_pep        │                  │ - notes         │
│ - risk_level    │                  └─────────────────┘
│ - became_client │
└─────────────────┘
     │
     │ has_many
     ├─────────────────────────────────┐
     ↓                                 ↓
┌─────────────────┐          ┌─────────────────┐
│BeneficialOwner  │          │   Transaction   │
│                 │          │                 │
│ - name          │          │ - date          │
│ - nationality   │          │ - type          │
│ - ownership_pct │          │ - value         │
│ - control_type  │          │ - commission    │
│ - is_pep        │          │ - property_cc   │
└─────────────────┘          │ - payment_method│
                             │ - agency_role   │
                             └─────────────────┘
```

### 3.3 Settings (Set Once)

Settings are stored as key-value pairs with types. They map directly to XBRL elements that rarely change.

```
Organization
     │
     │ has_many
     ↓
┌─────────────────────────────────────────────────────┐
│                    Setting                          │
│                                                     │
│ - key (e.g., 'edd_for_peps')                       │
│ - value                                             │
│ - value_type (boolean, integer, string, enum)       │
│ - xbrl_element (e.g., 'a4101')                     │
│ - category (entity_info, kyc, compliance, training) │
└─────────────────────────────────────────────────────┘

Categories:
├── entity_info
│   ├── entity_name
│   ├── total_employees
│   ├── compliance_officers
│   └── annual_revenue
│
├── kyc_procedures
│   ├── edd_for_peps (boolean)
│   ├── edd_for_high_risk_countries (boolean)
│   ├── edd_for_complex_structures (boolean)
│   ├── sdd_applied (boolean)
│   └── sdd_situations (multi-select)
│
├── compliance_policies
│   ├── written_aml_policy (boolean)
│   ├── policy_last_updated (date)
│   ├── risk_assessment_performed (boolean)
│   └── internal_controls (boolean)
│
└── training
    ├── training_frequency (enum: annual, biannual, etc.)
    ├── last_training_date (date)
    └── training_covers_aml (boolean)
```

### 3.4 Submissions (Annual)

```
Organization
     │
     │ has_many
     ↓
┌─────────────────┐
│   Submission    │
│                 │
│ - year          │
│ - status        │ (draft → validated → completed)
│ - started_at    │
│ - validated_at  │
│ - completed_at  │
└─────────────────┘
     │
     │ has_many
     ↓
┌─────────────────────────────────────────────────────┐
│               SubmissionValue                       │
│                                                     │
│ - element_name (e.g., 'a1101')                     │
│ - value                                             │
│ - source (calculated, from_settings, manual)        │
│ - overridden (boolean - user changed calculated)    │
│ - confirmed_at (timestamp - user reviewed)          │
└─────────────────────────────────────────────────────┘

Sources:
├── calculated    - Derived from CRM data (clients, transactions)
├── from_settings - Copied from Settings at submission time
└── manual        - Fresh answer required each year

**Concurrency Rules:**
- Only ONE draft submission per organization per year (enforced by unique index)
- Any user in the organization can view/continue the active draft
- No user locking; collaborative access to single draft
- "Start Submission" button creates draft if none exists, or resumes existing draft
- Once status = `completed`, submission is immutable (create new draft for corrections)
```

### 3.5 Database Schema

```ruby
# Organizations (extends Jumpstart Account)
create_table :organizations do |t|
  t.references :account, foreign_key: true
  t.string :name, null: false
  t.string :rci_number, null: false  # Monaco: Registre du Commerce et d'Industrie
  t.string :country, default: 'MC'
  t.timestamps
end

# =============================================================================
# SETTINGS (Set Once - rarely changes)
# =============================================================================

create_table :settings do |t|
  t.references :organization, foreign_key: true
  t.string :key, null: false             # e.g., 'edd_for_peps', 'total_employees'
  t.string :value                        # stored as string, cast based on value_type
  t.string :value_type, null: false      # boolean, integer, decimal, string, date, enum
  t.string :xbrl_element                 # e.g., 'a4101' - maps to XBRL taxonomy
  t.string :category, null: false        # entity_info, kyc, compliance, training
  t.timestamps

  t.index [:organization_id, :key], unique: true
end

# =============================================================================
# CRM DATA (Year-round usage)
# =============================================================================

# Clients
create_table :clients do |t|
  t.references :organization, foreign_key: true
  t.string :name, null: false
  t.string :client_type, null: false    # PP (natural person), PM (legal entity), TRUST
  t.string :nationality                  # ISO country code
  t.string :residence_country            # ISO country code
  t.boolean :is_pep, default: false
  t.string :pep_type                     # DOMESTIC, FOREIGN, INTL_ORG
  t.string :risk_level                   # LOW, MEDIUM, HIGH
  t.boolean :is_vasp, default: false
  t.string :vasp_type                    # CUSTODIAN, EXCHANGE, ICO, OTHER
  t.string :legal_person_type            # SCI, SARL, SAM, SNC, SA, OTHER (if PM)
  t.string :business_sector              # for high-risk categorization
  t.datetime :became_client_at
  t.string :rejection_reason             # if relationship rejected/terminated
  t.text :notes
  t.timestamps
end

# Beneficial Owners (for legal entities)
create_table :beneficial_owners do |t|
  t.references :client, foreign_key: true
  t.string :name, null: false
  t.string :nationality
  t.string :residence_country
  t.decimal :ownership_pct, precision: 5, scale: 2
  t.string :control_type                 # DIRECT, INDIRECT, REPRESENTATIVE
  t.boolean :is_pep, default: false
  t.string :pep_type
  t.timestamps
end

# Transactions (linked to clients, not submissions)
create_table :transactions do |t|
  t.references :organization, foreign_key: true
  t.references :client, foreign_key: true
  t.string :reference                    # user's reference number (optional)
  t.date :transaction_date, null: false
  t.string :transaction_type, null: false # PURCHASE, SALE, RENTAL
  t.decimal :transaction_value, precision: 15, scale: 2
  t.decimal :commission_amount, precision: 15, scale: 2
  t.string :property_country, default: 'MC'
  t.string :payment_method               # WIRE, CASH, CHECK, CRYPTO, MIXED
  t.decimal :cash_amount, precision: 15, scale: 2
  t.string :agency_role                  # BUYER_AGENT, SELLER_AGENT, DUAL_AGENT
  t.string :purchase_purpose             # RESIDENCE, INVESTMENT (for purchases)
  t.text :notes
  t.timestamps
end

# STR Reports (Suspicious Transaction Reports)
create_table :str_reports do |t|
  t.references :organization, foreign_key: true
  t.references :client, foreign_key: true, optional: true
  t.references :transaction, foreign_key: true, optional: true
  t.date :report_date, null: false
  t.string :reason, null: false          # CASH, PEP, UNUSUAL_PATTERN, OTHER
  t.text :notes
  t.timestamps
end

# =============================================================================
# SUBMISSIONS (Annual)
# =============================================================================

create_table :submissions do |t|
  t.references :organization, foreign_key: true
  t.integer :year, null: false
  t.string :taxonomy_version, default: '2025'
  t.string :status, default: 'draft'     # draft, in_review, validated, completed
  t.datetime :started_at
  t.datetime :validated_at
  t.datetime :completed_at
  t.timestamps

  t.index [:organization_id, :year], unique: true
end

# Submission Values (snapshot of all XBRL element values)
create_table :submission_values do |t|
  t.references :submission, foreign_key: true
  t.string :element_name, null: false    # e.g., 'a1101', 'a2104B'
  t.string :value
  t.string :source, null: false          # calculated, from_settings, manual
  t.boolean :overridden, default: false  # user changed a calculated value
  t.datetime :confirmed_at               # when user reviewed/confirmed this value
  t.timestamps

  t.index [:submission_id, :element_name], unique: true
end
```

### 3.6 Data Retention Policy

**Regulatory Requirement:** All client records, transaction data, beneficial owner information, and STR reports MUST be retained for **5 years after the business relationship ends** (per AMSF AML/CFT regulations).

- **Soft delete required:** Records are marked `deleted_at` but not purged until retention period expires
- **Relationship end date:** Tracked via `relationship_ended_at` on Client model
- **Automated purge:** Background job checks eligibility and hard-deletes after 5-year window
- **Audit trail:** Deletion events logged for compliance verification

### 3.7 Enums and Constants

```ruby
# app/models/concerns/amsf_constants.rb
module AmsfConstants
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

  SUBMISSION_VALUE_SOURCES = %w[calculated from_settings manual].freeze
end
```

### 3.8 Security & Multi-Tenancy

**Tenant Isolation Rules:**

- All CRM data (clients, transactions, beneficial owners, STRs, submissions) MUST be scoped to `current_account.organization`
- Cross-tenant access attempts MUST return **404 Not Found** (never 403 Forbidden) to prevent information leakage
- Pundit policies enforce scoping at controller level; models use `default_scope` as defense-in-depth
- Direct object reference attacks mitigated by always resolving resources through organization scope

**Implementation Pattern:**
```ruby
# All queries go through organization scope
@client = current_organization.clients.find(params[:id])
# Returns 404 if client belongs to different organization (not 403)
```

### 3.9 Audit Trail

**Scope:** Authentication events + CRUD operations on compliance-sensitive data.

**Logged Events:**

| Category | Events |
|----------|--------|
| Authentication | Login success/failure, logout, password reset, session expiry |
| Clients | Create, update, delete (soft), restore |
| Beneficial Owners | Create, update, delete |
| Transactions | Create, update, delete |
| STR Reports | Create, update, delete |
| Submissions | Create, step transitions, validation attempts, XBRL downloads |
| Settings | Any policy/entity info changes |

**Audit Record Structure:**
```ruby
# audit_logs table
- id, organization_id, user_id
- action (create/update/delete/login/download/etc.)
- auditable_type, auditable_id (polymorphic)
- metadata (JSON: changed fields summary, IP address, user agent)
- created_at
```

**Retention:** Audit logs follow same 5-year retention policy as source data.

---

## 4. Feature Specifications

### 4.1 Dashboard (Home)

**Purpose:** At-a-glance view of CRM activity and submission status.

**UI: Dashboard**
```
┌─────────────────────────────────────────────────────────────────┐
│ [AppName]                    Agence Immobilière Monaco  [⚙️]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────┐  ┌─────────────────────────┐  │
│  │ 📊 This Year (2025)         │  │ 📋 AMSF Submission      │  │
│  │                             │  │                         │  │
│  │ Clients:        42          │  │ Status: Not started     │  │
│  │ Transactions:   28          │  │ Deadline: March 31      │  │
│  │ Total Value:    €24.5M      │  │                         │  │
│  │ STRs Filed:     1           │  │ [Start 2025 Submission] │  │
│  └─────────────────────────────┘  └─────────────────────────┘  │
│                                                                 │
│  Recent Transactions                               [View All →] │
│  ─────────────────────────────────────────────────────────────  │
│  Nov 28  │ Purchase │ €2.1M  │ Jean Dupont      │ Monaco       │
│  Nov 15  │ Sale     │ €1.8M  │ ACME Holdings    │ Monaco       │
│  Nov 03  │ Rental   │ €36K   │ Marie Laurent    │ Monaco       │
│                                                                 │
│  [+ Add Transaction]  [+ Add Client]                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Clients (CRM Core)

**Purpose:** Manage client records - the core of the CRM.

**UI: Client List**
```
┌─────────────────────────────────────────────────────────────────┐
│ Clients                                              [+ Add]    │
├─────────────────────────────────────────────────────────────────┤
│ 🔍 Search...              [All Types ▼] [All Risk ▼] [PEP ▼]   │
├─────────────────────────────────────────────────────────────────┤
│ Name          │ Type │ Nationality │ Risk │ PEP │ Txns │ ⋮     │
│ Jean Dupont   │ PP   │ 🇫🇷 FR      │ MED  │ No  │ 3    │ ⋮     │
│ ACME Holdings │ PM   │ 🇱🇺 LU      │ HIGH │ No  │ 1    │ ⋮     │
│ Boris Petrov  │ PP   │ 🇷🇺 RU      │ HIGH │ Yes │ 2    │ ⋮     │
├─────────────────────────────────────────────────────────────────┤
│                                           Showing 1-25 of 42    │
└─────────────────────────────────────────────────────────────────┘
```

**UI: Client Detail (Legal Entity with BOs)**
```
┌─────────────────────────────────────────────────────────────────┐
│ ACME Holdings                                     [Edit] [Delete]│
├─────────────────────────────────────────────────────────────────┤
│ Type: Legal Entity (PM)        Nationality: 🇱🇺 Luxembourg       │
│ Legal Form: SARL               Residence: Luxembourg            │
│ Risk Level: HIGH               PEP: No                          │
│ Client Since: Jan 15, 2024     Sector: Investment               │
│                                                                 │
│ ─── Beneficial Owners (3) ────────────────────────── [+ Add]   │
│ ┌─────────────────────────────────────────────────────────────┐│
│ │ Name           │ Nationality │ Ownership │ Control  │ PEP   ││
│ │ Pierre Martin  │ 🇫🇷 FR      │ 40%       │ Direct   │ No    ││
│ │ Sophie Blanc   │ 🇲🇨 MC      │ 35%       │ Direct   │ No    ││
│ │ Hans Mueller   │ 🇨🇭 CH      │ 25%       │ Indirect │ No    ││
│ └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ─── Transactions (2) ────────────────────────────────────────  │
│ Mar 10, 2025 │ PURCHASE │ €5,000,000 │ Monaco property         │
│ Jun 22, 2024 │ PURCHASE │ €2,100,000 │ Monaco property         │
│                                                                 │
│ Notes:                                                          │
│ Complex corporate structure, requires enhanced due diligence.   │
└─────────────────────────────────────────────────────────────────┘
```

**Behaviors:**
- Inline editing via Turbo Frames
- Auto-prompt for beneficial owners when client_type = PM
- Risk level suggestions based on nationality/PEP status

### 4.3 Transactions

**Purpose:** Record real estate transactions as they happen.

**UI: Transaction List**
```
┌─────────────────────────────────────────────────────────────────┐
│ Transactions                                         [+ Add]    │
├─────────────────────────────────────────────────────────────────┤
│ 🔍 Search...           [All Types ▼] [2025 ▼] [All Payment ▼]  │
├─────────────────────────────────────────────────────────────────┤
│ Date       │ Type     │ Client        │ Value    │ Payment │ ⋮ │
│ 2025-11-28 │ PURCHASE │ Jean Dupont   │ €2.1M    │ Wire    │ ⋮ │
│ 2025-11-15 │ SALE     │ ACME Holdings │ €1.8M    │ Wire    │ ⋮ │
│ 2025-11-03 │ RENTAL   │ Marie Laurent │ €36K/yr  │ Wire    │ ⋮ │
├─────────────────────────────────────────────────────────────────┤
│                                          Showing 1-25 of 28     │
└─────────────────────────────────────────────────────────────────┘
```

**UI: Add Transaction (Modal/Turbo Frame)**
```
┌─────────────────────────────────────────────────────────────────┐
│ Add Transaction                                         [×]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Date                  [2025-11-30      ] 📅                     │
│ Type                  [PURCHASE ▼]                              │
│                                                                 │
│ ─── Client ───────────────────────────────────                  │
│ Client                [Search clients...        ▼]              │
│                       [+ New Client]                            │
│                                                                 │
│ ─── Transaction Details ──────────────────────                  │
│ Value                 [€ 2,500,000      ]                       │
│ Commission            [€ 75,000         ]                       │
│ Property Location     [MC ▼] Monaco                             │
│ Agency Role           [BUYER_AGENT ▼]                           │
│ Purchase Purpose      [RESIDENCE ▼]  (for purchases only)       │
│                                                                 │
│ ─── Payment ──────────────────────────────────                  │
│ Payment Method        [WIRE ▼]                                  │
│ Cash Amount           [€ 0             ] (if CASH/MIXED)        │
│                                                                 │
│ Reference (optional)  [2025-042        ]                        │
│ Notes                 [                               ]         │
│                                                                 │
│                              [Cancel]  [Save Transaction]       │
└─────────────────────────────────────────────────────────────────┘
```

**Behaviors:**
- Turbo Frame for inline add/edit (no page reload)
- Client selector with search + quick-create option
- Payment method drives cash_amount field visibility
- Purchase purpose only shown for PURCHASE type

### 4.4 STR Reports

**Purpose:** Document suspicious transaction reports filed with authorities.

**UI: STR List**
```
┌─────────────────────────────────────────────────────────────────┐
│ STR Reports                                          [+ Add]    │
├─────────────────────────────────────────────────────────────────┤
│ Date       │ Reason           │ Client        │ Transaction │ ⋮ │
│ 2025-05-15 │ Cash > €10K      │ Ahmed Hassan  │ 2025-005    │ ⋮ │
│ 2025-06-02 │ PEP involvement  │ Boris Petrov  │ —           │ ⋮ │
├─────────────────────────────────────────────────────────────────┤
│                                            Showing 1-2 of 2     │
└─────────────────────────────────────────────────────────────────┘
```

### 4.5 Settings (Set Once)

**Purpose:** Configure entity information and compliance policies. These values rarely change and are reused across submissions.

**UI: Settings Page**
```
┌─────────────────────────────────────────────────────────────────┐
│ Settings                                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌─── Entity Information ───────────────────────────────────────┐│
│ │                                                              ││
│ │ Company Name        [Agence Immobilière Monaco    ]          ││
│ │ RCI Number          [12345678                     ]          ││
│ │ Total Employees     [5     ]                                 ││
│ │ Compliance Officers [1     ]                                 ││
│ │ Annual Revenue      [€ 850,000                    ]          ││
│ │                                                              ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── KYC Procedures ───────────────────────────────────────────┐│
│ │                                                              ││
│ │ Enhanced Due Diligence (EDD) applied for:                    ││
│ │ ☑ PEP clients                                               ││
│ │ ☑ High-risk jurisdictions                                   ││
│ │ ☑ Complex ownership structures                              ││
│ │ ☐ Cash transactions > €10,000                               ││
│ │                                                              ││
│ │ Simplified Due Diligence (SDD) applied?  [No ▼]             ││
│ │                                                              ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── Compliance Policies ──────────────────────────────────────┐│
│ │                                                              ││
│ │ Written AML/CFT policy?          [Yes ▼]                    ││
│ │ Policy last updated              [2024-06-15      ] 📅       ││
│ │ Risk assessment performed?       [Yes ▼]                    ││
│ │ Internal controls in place?      [Yes ▼]                    ││
│ │                                                              ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── Training ─────────────────────────────────────────────────┐│
│ │                                                              ││
│ │ Training frequency               [Annual ▼]                 ││
│ │ Last training date               [2025-02-10      ] 📅       ││
│ │ Training covers AML/CFT?         [Yes ▼]                    ││
│ │                                                              ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│                                              [Save Settings]    │
└─────────────────────────────────────────────────────────────────┘
```

**Behaviors:**
- Auto-save on change (optimistic UI with Turbo)
- Settings map directly to XBRL elements
- Shown in onboarding wizard for new users
- Changes here update future submissions automatically

### 4.6 Annual Submission (Streamlined)

**Purpose:** Quick review and download of XBRL file. Most work is already done via CRM data and Settings.

**Streamlined Structure (4 steps, not 9):**
```
Step 1: Review Aggregates     (calculated from CRM - just verify)
Step 2: Confirm Policies      (from Settings - one-click confirm)
Step 3: Fresh Questions       (only questions that MUST be re-answered)
Step 4: Validate & Download   (XULE validation + XBRL download)
```

**UI: Step 1 - Review Aggregates**
```
┌─────────────────────────────────────────────────────────────────┐
│ 2025 AMSF Submission                              Step 1 of 4   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Review Calculated Values                                        │
│ ─────────────────────────────────────────────────────────────── │
│ These values were calculated from your CRM data.                │
│ Review and correct if needed.                                   │
│                                                                 │
│ ┌─── Client Statistics ────────────────────────────────────────┐│
│ │                                                              ││
│ │ Total clients                    42                          ││
│ │   Natural persons                30                          ││
│ │   Legal entities                 10                          ││
│ │   Trusts                          2                          ││
│ │                                                              ││
│ │ PEP clients                       3                          ││
│ │ High-risk clients                 5                          ││
│ │                                         [Edit if incorrect]  ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── Transaction Statistics ───────────────────────────────────┐│
│ │                                                              ││
│ │ Total transactions               28        Value: €24.5M     ││
│ │   Purchases                      12        €15.2M            ││
│ │   Sales                           8        €9.1M             ││
│ │   Rentals                         8        €180K             ││
│ │                                                              ││
│ │ Cash transactions                 2        €450K             ││
│ │ Crypto transactions               0        €0                ││
│ │                                         [Edit if incorrect]  ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── STR Reports ──────────────────────────────────────────────┐│
│ │                                                              ││
│ │ STRs filed this year              1                          ││
│ │                                         [Edit if incorrect]  ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│                              [Save & Continue →]                │
└─────────────────────────────────────────────────────────────────┘
```

**UI: Step 2 - Confirm Policies**
```
┌─────────────────────────────────────────────────────────────────┐
│ 2025 AMSF Submission                              Step 2 of 4   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Confirm Policy Settings                                         │
│ ─────────────────────────────────────────────────────────────── │
│ These values come from your Settings. Confirm they're still     │
│ accurate for 2025, or update in Settings.                       │
│                                                                 │
│ ┌─── Entity Information ───────────────────────────────────────┐│
│ │ Company: Agence Immobilière Monaco                     [✓]  ││
│ │ RCI: 12345678                                          [✓]  ││
│ │ Employees: 5 (1 compliance officer)                    [✓]  ││
│ │ Annual Revenue: €850,000                               [✓]  ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── KYC Procedures ───────────────────────────────────────────┐│
│ │ EDD for PEPs: Yes                                      [✓]  ││
│ │ EDD for high-risk countries: Yes                       [✓]  ││
│ │ EDD for complex structures: Yes                        [✓]  ││
│ │ SDD applied: No                                        [✓]  ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ┌─── Compliance & Training ────────────────────────────────────┐│
│ │ Written AML policy: Yes (updated Jun 2024)             [✓]  ││
│ │ Risk assessment performed: Yes                         [✓]  ││
│ │ Training: Annual (last Feb 2025)                       [✓]  ││
│ └──────────────────────────────────────────────────────────────┘│
│                                                                 │
│ ☑ All 15 policy settings confirmed                             │
│                                                                 │
│ [← Back]   [Edit in Settings]        [Confirm All & Continue →] │
└─────────────────────────────────────────────────────────────────┘
```

**UI: Step 3 - Fresh Questions (Only What's Needed)**
```
┌─────────────────────────────────────────────────────────────────┐
│ 2025 AMSF Submission                              Step 3 of 4   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Annual Questions                                                │
│ ─────────────────────────────────────────────────────────────── │
│ These questions require fresh answers each year.                │
│                                                                 │
│ 1. Did you reject or terminate any client relationships        │
│    for AML/CFT reasons this year?                               │
│                                                                 │
│    [Yes ▼]                                                      │
│                                                                 │
│    If yes, how many?  [2    ]                                   │
│    Reasons: ☑ Suspicious source of funds                       │
│             ☑ Unable to verify beneficial owner                │
│             ☐ PEP without adequate documentation               │
│             ☐ Other AML/CFT concerns                           │
│                                                                 │
│ 2. Did you make any changes to your AML/CFT procedures         │
│    this year?                                                   │
│                                                                 │
│    [No ▼]                                                       │
│                                                                 │
│ 3. Did you identify any new high-risk situations that          │
│    weren't previously covered by your procedures?               │
│                                                                 │
│    [No ▼]                                                       │
│                                                                 │
│ [← Back]                                 [Save & Continue →]    │
└─────────────────────────────────────────────────────────────────┘
```

**UI: Step 4 - Validate & Download**
```
┌─────────────────────────────────────────────────────────────────┐
│ 2025 AMSF Submission                              Step 4 of 4   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ Validate & Download                                             │
│ ─────────────────────────────────────────────────────────────── │
│                                                                 │
│ Running 275 AMSF validation rules...                            │
│ [████████████████████████████████████████] 100%                 │
│                                                                 │
│ ✅ All validation rules passed                                  │
│                                                                 │
│ ─── Submission Summary ───────────────────────────────────────  │
│                                                                 │
│ Organization:     Agence Immobilière Monaco                     │
│ RCI Number:       12345678                                      │
│ Reporting Year:   2025                                          │
│                                                                 │
│ Data included:                                                  │
│ • 42 clients (30 natural, 10 legal, 2 trusts)                  │
│ • 28 transactions (€24.5M total value)                         │
│ • 1 STR report                                                  │
│ • 15 policy confirmations                                       │
│ • 3 annual questions answered                                   │
│                                                                 │
│            ┌──────────────────────────────────┐                │
│            │   📥 Download XBRL File          │                │
│            │   amsf_2025_12345678.xml         │                │
│            └──────────────────────────────────┘                │
│                                                                 │
│ ─── Next Steps ───────────────────────────────────────────────  │
│                                                                 │
│ 1. Download the XBRL file above                                 │
│ 2. Log into Strix portal                                        │
│ 3. Upload your file - all 180+ fields auto-populate            │
│ 4. Review and submit to AMSF                                    │
│                                                                 │
│ [← Back]                               [Mark as Completed]      │
└─────────────────────────────────────────────────────────────────┘
```

**If Validation Fails:**
```
┌─────────────────────────────────────────────────────────────────┐
│ 2025 AMSF Submission                              Step 4 of 4   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ❌ Validation Failed - 2 issues found                           │
│                                                                 │
│ ─── Errors (must fix) ────────────────────────────────────────  │
│                                                                 │
│ ❌ Client totals inconsistent                                   │
│    Total clients (42) ≠ sum of types (30 + 10 + 3 = 43)         │
│    → Check your CRM data for duplicate or miscategorized clients│
│    [Go to Clients]                                              │
│                                                                 │
│ ❌ PEP count exceeds client subset                              │
│    Foreign PEPs (5) > Foreign clients (3)                       │
│    → Update PEP flags on client records                         │
│    [Go to Clients]                                              │
│                                                                 │
│ ─── Warnings ─────────────────────────────────────────────────  │
│                                                                 │
│ ⚠️ High cash ratio (may trigger AMSF review)                    │
│    40% of transaction value is cash (typical: <5%)              │
│    → This is allowed but will be flagged. Confirm data is correct│
│                                                                 │
│ [← Back]                         [Fix Issues & Re-validate]     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Technical Architecture

### 5.1 System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                            │
│                              │                                  │
│                         HTTPS/WSS                               │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Rails Application                     │   │
│  │                                                          │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │   │
│  │  │   Hotwire    │ │   Jumpstart  │ │   Business       │ │   │
│  │  │ Turbo/Stim.  │ │   Pro Auth   │ │   Logic          │ │   │
│  │  └──────────────┘ └──────────────┘ └──────────────────┘ │   │
│  │                                                          │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │   │
│  │  │   Excel      │ │ Calculation  │ │   XBRL           │ │   │
│  │  │   Import     │ │   Engine     │ │   Generator      │ │   │
│  │  └──────────────┘ └──────────────┘ └──────────────────┘ │   │
│  │                              │                           │   │
│  └──────────────────────────────┼───────────────────────────┘   │
│                                 │                               │
│                            HTTP API                             │
│                                 │                               │
│                                 ▼                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Python Validation Service                   │   │
│  │                                                          │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ │   │
│  │  │   FastAPI    │ │   Arelle     │ │   XULE Rules     │ │   │
│  │  │   Endpoint   │ │   Processor  │ │   (275 rules)    │ │   │
│  │  └──────────────┘ └──────────────┘ └──────────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     PostgreSQL                           │   │
│  │                                                          │   │
│  │  organizations │ submissions │ transactions │ clients    │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Rails Application Structure

```
app/
├── controllers/
│   ├── dashboard_controller.rb
│   ├── transactions_controller.rb
│   ├── clients_controller.rb
│   ├── beneficial_owners_controller.rb
│   ├── submissions_controller.rb
│   ├── submission_steps_controller.rb    # Wizard steps
│   └── imports_controller.rb             # Excel import
│
├── models/
│   ├── organization.rb
│   ├── submission.rb
│   ├── submission_value.rb
│   ├── transaction.rb
│   ├── client.rb
│   ├── beneficial_owner.rb
│   ├── str_report.rb
│   └── concerns/
│       └── amsf_constants.rb
│
├── services/
│   ├── excel_import_service.rb           # Parse & import Excel
│   ├── calculation_engine.rb             # Auto-calculate values
│   ├── xbrl_generator.rb                 # Generate XBRL XML
│   ├── validation_service.rb             # Call Python validator
│   └── prefill_service.rb                # Load previous year data
│
├── views/
│   ├── transactions/
│   ├── clients/
│   ├── submissions/
│   └── submission_steps/
│       ├── entity_info.html.erb
│       ├── transaction_review.html.erb
│       ├── client_statistics.html.erb
│       ├── payment_methods.html.erb
│       ├── compliance_policies.html.erb
│       ├── kyc_procedures.html.erb
│       ├── str_reporting.html.erb
│       ├── review.html.erb
│       └── generate.html.erb
│
└── javascript/
    └── controllers/                      # Stimulus controllers
        ├── import_controller.js
        ├── transaction_form_controller.js
        └── validation_controller.js
```

### 5.3 Key Service Classes

```ruby
# app/services/calculation_engine.rb
class CalculationEngine
  def initialize(submission)
    @submission = submission
    @org = submission.organization
  end

  def calculate_all
    results = {}

    # Client statistics
    results.merge!(calculate_client_stats)

    # Transaction statistics
    results.merge!(calculate_transaction_stats)

    # Payment method statistics
    results.merge!(calculate_payment_stats)

    # PEP statistics
    results.merge!(calculate_pep_stats)

    # Beneficial owner statistics
    results.merge!(calculate_bo_stats)

    results
  end

  private

  def calculate_client_stats
    clients = @org.clients

    {
      'a1101' => clients.count,                           # Total clients
      'a1102' => clients.where(client_type: 'PP').count,  # Natural persons
      'a11502B' => clients.where(client_type: 'PM').count, # Legal entities
      'a11802B' => clients.where(client_type: 'TRUST').count, # Trusts
      # ... nationality breakdowns
      # ... by transaction role
    }
  end

  def calculate_transaction_stats
    txns = @submission.transactions

    {
      'a2101B' => txns.count,
      'a2102' => txns.where(transaction_type: 'PURCHASE').count,
      'a2103' => txns.where(transaction_type: 'SALE').count,
      'a2104' => txns.where(transaction_type: 'RENTAL').count,
      'a2104B' => txns.sum(:transaction_value),
      # ... by country, by payment method, etc.
    }
  end

  # ... more calculation methods
end
```

```ruby
# app/services/xbrl_generator.rb
class XbrlGenerator
  NAMESPACES = {
    'xmlns:xbrli' => 'http://www.xbrl.org/2003/instance',
    'xmlns:strix' => 'https://amlcft.amsf.mc/dcm/DTS/strix_Real_Estate_AML_CFT_survey_2025/fr',
    'xmlns:iso4217' => 'http://www.xbrl.org/2003/iso4217',
    # ... other namespaces
  }.freeze

  def initialize(submission)
    @submission = submission
    @values = submission.submission_values.index_by(&:element_name)
  end

  def generate
    Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.xbrl(NAMESPACES) do
        build_schema_refs(xml)
        build_contexts(xml)
        build_units(xml)
        build_facts(xml)
      end
    end.to_xml
  end

  private

  def build_contexts(xml)
    # Entity context
    xml['xbrli'].context(id: 'ctx_entity') do
      xml['xbrli'].entity do
        xml['xbrli'].identifier(@submission.organization.rci_number, scheme: 'http://www.amsf.mc')
      end
      xml['xbrli'].period do
        xml['xbrli'].instant(@submission.report_date.to_s)
      end
    end

    # Country dimension contexts
    # ... build dimensional contexts
  end

  def build_facts(xml)
    @values.each do |element_name, sv|
      xml['strix'].send(element_name, sv.value, contextRef: 'ctx_entity', unitRef: unit_for(element_name))
    end
  end
end
```

---

## 6. XBRL Generation

### 6.1 Element Mapping

The calculation engine maps questionnaire answers to XBRL taxonomy elements:

```ruby
# config/amsf_element_mapping.yml
client_statistics:
  total_clients:
    element: a1101
    type: integer
    source: calculated
    formula: "clients.count"

  natural_persons:
    element: a1102
    type: integer
    source: calculated
    formula: "clients.where(client_type: 'PP').count"

  # ... 185 total mappings

transaction_statistics:
  total_transactions:
    element: a2101B
    type: integer
    source: calculated

  total_value:
    element: a2104B
    type: monetary
    unit: EUR
    source: calculated
    formula: "transactions.sum(:transaction_value)"
```

### 6.2 Calculation Dependencies

Some values depend on others. The engine handles this:

```ruby
# Dependency graph (simplified)
DEPENDENCIES = {
  'a1101' => [],  # Total clients - no deps
  'a1106B' => ['a1101'],  # Buyers - must have total first
  'a1106W' => ['a1101'],  # Sellers - must have total first
  # Validation: a1101 >= a1106B (can have buyer-only clients)
}
```

### 6.3 Country Dimension Handling

Many elements require country breakdowns:

```ruby
def build_country_dimensions(xml)
  nationality_counts = clients.group(:nationality).count

  nationality_counts.each do |country_code, count|
    context_id = "ctx_country_#{country_code}"

    # Build dimensional context
    xml['xbrli'].context(id: context_id) do
      xml['xbrli'].entity { ... }
      xml['xbrli'].period { ... }
      xml['xbrli'].scenario do
        xml['xbrldi'].explicitMember(
          country_code,
          dimension: 'strix:CountryDimension'
        )
      end
    end

    # Build fact with dimensional context
    xml['strix'].a1101(count, contextRef: context_id)
  end
end
```

---

## 7. Validation Service

### 7.1 Python Service (FastAPI + Arelle)

```python
# validation_service/main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import subprocess
import tempfile
import json
import os

app = FastAPI()

TAXONOMY_PATH = "/app/taxonomies/strix_Real_Estate_AML_CFT_survey_2025.xsd"
RULESET_PATH = "/app/taxonomies/strix_ruleset.zip"

class ValidationRequest(BaseModel):
    xbrl_content: str

class ValidationResult(BaseModel):
    valid: bool
    errors: list[dict]
    warnings: list[dict]

@app.post("/validate", response_model=ValidationResult)
async def validate_xbrl(request: ValidationRequest):
    # Write XBRL to temp file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.xml', delete=False) as f:
        f.write(request.xbrl_content)
        temp_path = f.name

    try:
        # Run Arelle validation
        result = subprocess.run([
            'arelleCmdLine',
            '--file', temp_path,
            '--validate',
            '--plugins', 'xule/plugin/xule',
            '--xule-rule-set', RULESET_PATH,
            '--xule-run',
            '--logFormat', 'json'
        ], capture_output=True, text=True, timeout=60)

        # Parse results
        errors, warnings = parse_arelle_output(result.stderr)

        return ValidationResult(
            valid=len(errors) == 0,
            errors=errors,
            warnings=warnings
        )
    finally:
        os.unlink(temp_path)

def parse_arelle_output(output: str) -> tuple[list, list]:
    errors = []
    warnings = []

    for line in output.split('\n'):
        if not line.strip():
            continue
        try:
            entry = json.loads(line)
            if entry.get('level') == 'error':
                errors.append({
                    'code': entry.get('code'),
                    'message': entry.get('message'),
                    'element': entry.get('element')
                })
            elif entry.get('level') == 'warning':
                warnings.append({
                    'code': entry.get('code'),
                    'message': entry.get('message'),
                    'element': entry.get('element')
                })
        except json.JSONDecodeError:
            continue

    return errors, warnings

@app.get("/health")
async def health():
    return {"status": "ok"}
```

### 7.2 Dockerfile for Validation Service

```dockerfile
# validation_service/Dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Arelle
RUN pip install arelle-release aniso8601

# Install XULE plugin
RUN cd /usr/local/lib/python3.11/site-packages/arelle/plugin && \
    git clone https://github.com/xbrlus/xule.git

# Install FastAPI
RUN pip install fastapi uvicorn

# Copy taxonomy files
COPY taxonomies/ /app/taxonomies/

# Copy application
COPY main.py /app/main.py

WORKDIR /app

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 7.3 Rails Integration

```ruby
# app/services/validation_service.rb
class ValidationService
  VALIDATOR_URL = ENV.fetch('VALIDATOR_URL', 'http://localhost:8000')

  def initialize(xbrl_content)
    @xbrl_content = xbrl_content
  end

  def validate
    response = HTTP.post(
      "#{VALIDATOR_URL}/validate",
      json: { xbrl_content: @xbrl_content }
    )

    if response.status.success?
      JSON.parse(response.body.to_s, symbolize_names: true)
    else
      { valid: false, errors: [{ message: 'Validation service unavailable' }], warnings: [] }
    end
  rescue HTTP::Error => e
    { valid: false, errors: [{ message: "Connection error: #{e.message}" }], warnings: [] }
  end
end
```

### 7.4 Service Unavailability Handling

**Fallback Behavior:** If the validation service is unreachable or returns errors:

1. Display prominent warning: "⚠️ Validation service unavailable. File not validated against AMSF rules."
2. Allow user to download XBRL file anyway (unvalidated)
3. Mark submission as `downloaded_unvalidated` in audit log
4. Recommend: "Please retry validation before uploading to Strix, or manually verify with AMSF."

**UI Treatment:**
- Warning banner (yellow/orange) replaces green "All rules passed"
- Download button remains enabled but labeled "Download Unvalidated File"
- User must acknowledge warning checkbox before download proceeds

---

## 8. Infrastructure

### 8.1 Server Setup (Hetzner)

**Recommended:** Hetzner CPX21 (3 vCPU, 4GB RAM, 80GB SSD) - ~€8/month

Located in: **Falkenstein or Nuremberg** (EU, close to Monaco)

### 8.2 Kamal Configuration

```yaml
# config/deploy.yml
service: appname

image: your-registry/appname

servers:
  web:
    hosts:
      - 123.45.67.89
    labels:
      traefik.http.routers.appname.rule: Host(`app.yourdomain.com`)
      traefik.http.routers.appname.tls.certresolver: letsencrypt

registry:
  server: ghcr.io
  username:
    - KAMAL_REGISTRY_USERNAME
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    RAILS_ENV: production
    VALIDATOR_URL: http://appname-validator:8000
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - SECRET_KEY_BASE

accessories:
  db:
    image: postgres:15
    host: 123.45.67.89
    port: 5432
    env:
      clear:
        POSTGRES_DB: appname_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  validator:
    image: your-registry/appname-validator
    host: 123.45.67.89
    port: 8000

traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "you@example.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: "web"
```

### 8.3 Backup Strategy

```bash
# /etc/cron.daily/backup-postgres
#!/bin/bash
DATE=$(date +%Y%m%d)
BACKUP_DIR=/backups

# Dump database
docker exec appname-db pg_dump -U postgres appname_production | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Upload to B2/S3
rclone copy $BACKUP_DIR/db_$DATE.sql.gz b2:appname-backups/

# Keep only last 30 days locally
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete
```

---

## 9. MVP Scope

### 9.1 In Scope (CRM-First)

| Feature | Priority | Notes |
|---------|----------|-------|
| **Authentication** | | |
| User auth (Jumpstart Pro) | P0 | Teams, accounts, billing ready |
| Organization setup | P0 | Name, RCI number |
| **CRM (Year-Round)** | | |
| Dashboard | P0 | At-a-glance stats, quick actions |
| Client management | P0 | CRUD, list, search, filters |
| Beneficial owner tracking | P0 | For legal entities (PM/TRUST) |
| Transaction logger | P0 | CRUD, list, search, filters |
| STR reports | P0 | CRUD, link to client/transaction |
| **Settings (Set Once)** | | |
| Entity information | P0 | Name, RCI, employees, revenue |
| Compliance policies | P0 | KYC procedures, training, etc. |
| **Annual Submission** | | |
| Calculation engine | P0 | Aggregates from CRM data |
| 4-step submission flow | P0 | Review → Confirm → Answer → Download |
| XBRL generation (Ruby) | P0 | Nokogiri-based |
| XULE validation (Python) | P0 | 275 rules via Arelle |
| **Polish** | | |
| Help text for fields | P1 | Inline explanations |
| Strix upload guide | P1 | Step-by-step instructions |

### 9.2 Out of Scope (Post-MVP)

| Feature | Reason |
|---------|--------|
| Excel import | Users enter via CRM; import can come later |
| Email reminders | Nice-to-have for engagement |
| Smart year-over-year diff | Complex change detection |
| Multi-industry taxonomies | Different XBRL schemas |
| API access | No demand yet |
| Mobile app | Web works on mobile |
| Advanced CRM (pipeline, docs) | Future expansion |
| Direct Strix submission | Would need FT Solutions partnership |

---

## 10. Implementation Phases

### Phase 1: Foundation

- [ ] Set up Jumpstart Pro project
- [ ] Configure Kamal deployment to Hetzner
- [ ] Set up PostgreSQL with backups
- [ ] Create Organization model (extends Account)
- [ ] Create Settings model with key-value storage
- [ ] Basic dashboard skeleton
- [ ] Onboarding flow for new organizations

### Phase 2: CRM Core

- [ ] Client CRUD with Turbo Frames
- [ ] Client list with search and filters
- [ ] Beneficial owner CRUD (nested under clients)
- [ ] Transaction CRUD with Turbo Frames
- [ ] Transaction list with search and filters
- [ ] STR report CRUD
- [ ] Dashboard with stats and recent activity

### Phase 3: Settings & Policies

- [ ] Settings UI with categories
- [ ] Entity information section
- [ ] KYC procedures section
- [ ] Compliance policies section
- [ ] Training section
- [ ] XBRL element mapping for settings

### Phase 4: Calculation Engine

- [ ] CalculationEngine service
- [ ] Client statistics calculations
- [ ] Transaction statistics calculations
- [ ] Payment method breakdowns
- [ ] PEP/risk level aggregations
- [ ] Unit tests for all calculations

### Phase 5: Annual Submission Flow

- [ ] Submission model and states
- [ ] Step 1: Review Aggregates UI
- [ ] Step 2: Confirm Policies UI
- [ ] Step 3: Fresh Questions UI
- [ ] SubmissionValue model with sources

### Phase 6: XBRL & Validation

- [ ] Port generate_xbrl.py to Ruby (Nokogiri)
- [ ] Build Python validation service (FastAPI + Arelle)
- [ ] Deploy validation service alongside Rails
- [ ] Step 4: Validate & Download UI
- [ ] Error display with fix guidance

### Phase 7: Polish & Beta

- [ ] Help text for fields
- [ ] Strix upload guide
- [ ] Error handling improvements
- [ ] Performance optimization
- [ ] Beta user recruitment (cousin + acquaintances)

---

## 11. Future: Excel Import

**Deferred to post-MVP.** When users already have data in spreadsheets, we can add import functionality.

### Approach

```
User uploads Excel → Parse sheets → Preview data → Map columns → Import to CRM
```

### Supported Sheets

1. **Transactions** - Bulk import deals
2. **Clients** - Import client list with types/nationalities
3. **Beneficial_Owners** - Import BO data linked to clients

### Implementation Notes

- Use `roo` or `creek` gem for Excel parsing
- Column auto-detection with manual override
- Preview with validation errors before import
- Duplicate detection (by name/date combination)
- Audit trail of imports

This feature becomes valuable when:
- User has historical data to migrate
- User prefers Excel for data entry
- User receives data from third parties in Excel format

---

## Appendix A: AMSF Element Reference

See `/Users/laurentcurau/projects/strix/EXCEL_TO_XBRL_MAPPING.md` for complete element mapping.

## Appendix B: Excel Template Specification

See `/Users/laurentcurau/projects/strix/EXCEL_TEMPLATE_SPEC.md` for import format details.

## Appendix C: Questionnaire Structure

See `/Users/laurentcurau/projects/strix/SIMPLIFIED_QUESTIONNAIRE.md` for the 27-question simplified flow.

---

**Document Status:** Updated Nov 30 - CRM-first approach

**Key Changes (Nov 30):**
- Shifted from questionnaire-first to CRM-first architecture
- Settings store stable policy answers (set once, reused)
- Submission reduced from 9 steps to 4 steps
- Excel import deferred to post-MVP
- Fresh questions only asked when truly needed each year

**Next Step:** Review and approve, then begin Phase 1 implementation.
