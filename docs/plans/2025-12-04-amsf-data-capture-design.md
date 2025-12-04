# AMSF Survey Data Capture Design

**Date**: 2025-12-04
**Status**: Approved
**Branch**: 012-amsf-taxonomy-compliance

## Goal

Minimize user effort at AMSF survey submission time by capturing all compliance data when it's "warm" during normal CRM use. The user should be able to review pre-calculated values and submit with near-zero manual data entry.

## Background

The AMSF annual AML/CFT survey requires 323 XBRL elements covering:
- Client statistics (96 elements)
- Transaction statistics (35 elements)
- Training and STR data (36 elements)
- Control/policy questions (105 elements)
- Revenue and other data (51 elements)

Current state:
- ~22 elements calculated from CRM (CalculationEngine)
- ~105 aC* control elements mapped to Settings
- ~196 elements not yet handled

## Design Principle

**Capture data at the point of the event, not at survey time.**

When an agent rejects a client, records a transaction, or conducts training, they capture the compliance-relevant details immediately. At survey submission time, everything is pre-calculated and the user simply reviews.

---

## Model Changes

### 1. Client Model Extensions

New fields to capture compliance decisions during client lifecycle:

| Field | Type | Purpose | Survey Elements |
|-------|------|---------|-----------------|
| `due_diligence_level` | enum | Standard/Simplified/Reinforced DD applied | a1203, a1203D, a1204S |
| `simplified_dd_reason` | string | Why SDD was applied (if applicable) | a1204S1 |
| `relationship_end_reason` | enum | Why relationship terminated | a14001 |
| `rejected_at` | datetime | When client was rejected | a11301, a11302 |
| `professional_category` | enum | Legal profession, accountant, etc. | a11602B, a11702B |
| `source_of_funds_verified` | boolean | Was source of funds documented? | a13501B |
| `source_of_wealth_verified` | boolean | Was source of wealth documented? | a13601 series |

**Enum values:**

```ruby
# due_diligence_level
DUE_DILIGENCE_LEVELS = %w[STANDARD SIMPLIFIED REINFORCED].freeze

# relationship_end_reason
RELATIONSHIP_END_REASONS = %w[
  CLIENT_REQUEST
  AML_CONCERN
  INACTIVITY
  BUSINESS_DECISION
  OTHER
].freeze

# professional_category
PROFESSIONAL_CATEGORIES = %w[
  LEGAL
  ACCOUNTANT
  NOTARY
  REAL_ESTATE
  FINANCIAL
  OTHER
  NONE
].freeze
```

### 2. Transaction Model Extensions

New fields to capture transaction-level compliance details:

| Field | Type | Purpose | Survey Elements |
|-------|------|---------|-----------------|
| `property_type` | enum | Residential/Commercial/Land | a2113B, a2113W |
| `is_new_construction` | boolean | New build vs resale | a2114A, a2114AB |
| `counterparty_is_pep` | boolean | Is the other party a PEP? | a2110B, a2110W |
| `counterparty_country` | string | Country of buyer/seller (ISO 3166-1 alpha-2) | Geographic stats |
| `rental_annual_value` | decimal | Annual rental value (for rentals) | a1106BRENTALS |
| `rental_tenant_type` | enum | Natural person/Legal entity tenant | a1802TOLA series |

**Enum values:**

```ruby
# property_type
PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL LAND MIXED].freeze

# rental_tenant_type
TENANT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY].freeze
```

### 3. BeneficialOwner Model Extensions

| Field | Type | Purpose |
|-------|------|---------|
| `source_of_wealth_verified` | boolean | Was BO's source of wealth documented? |
| `identification_verified` | boolean | Was identity document verified? |

### 4. New Model: Training

Tracks staff AML/CFT training sessions:

```ruby
# db/migrate/xxx_create_trainings.rb
create_table :trainings do |t|
  t.references :organization, null: false, foreign_key: true
  t.date :training_date, null: false
  t.string :training_type, null: false  # initial, refresher, specialized
  t.string :topic, null: false          # aml_basics, pep_screening, str_filing, etc.
  t.string :provider, null: false       # internal, external, amsf, online
  t.integer :staff_count, null: false
  t.decimal :duration_hours, precision: 4, scale: 2
  t.text :notes
  t.timestamps
end

add_index :trainings, [:organization_id, :training_date]
```

**Enum values:**

```ruby
TRAINING_TYPES = %w[INITIAL REFRESHER SPECIALIZED].freeze

TRAINING_TOPICS = %w[
  AML_BASICS
  PEP_SCREENING
  STR_FILING
  RISK_ASSESSMENT
  SANCTIONS
  KYC_PROCEDURES
  OTHER
].freeze

TRAINING_PROVIDERS = %w[INTERNAL EXTERNAL AMSF ONLINE].freeze
```

**Survey elements covered:** a3201, a3202, a3203, a3204, a3205, a3301, a3302, a3303

### 5. New Model: ManagedProperty

Tracks ongoing property management contracts (gestion locative):

```ruby
# db/migrate/xxx_create_managed_properties.rb
create_table :managed_properties do |t|
  t.references :organization, null: false, foreign_key: true
  t.references :client, null: false, foreign_key: true  # The landlord
  t.string :property_address, null: false
  t.string :property_type, default: 'RESIDENTIAL'  # residential, commercial
  t.date :management_start_date, null: false
  t.date :management_end_date  # null = still active
  t.decimal :monthly_rent, precision: 15, scale: 2
  t.decimal :management_fee_percent, precision: 5, scale: 2  # e.g., 8.00 for 8%
  t.decimal :management_fee_fixed, precision: 15, scale: 2   # alternative: fixed fee
  t.string :tenant_name
  t.string :tenant_type  # natural_person, legal_entity
  t.string :tenant_country  # ISO 3166-1 alpha-2
  t.boolean :tenant_is_pep, default: false
  t.text :notes
  t.timestamps
end

add_index :managed_properties, [:organization_id, :management_end_date]
add_index :managed_properties, :client_id
```

**Survey elements covered:**
- `a3804` - Management revenue (calculated from fees)
- `aACTIVEPS` - Activity flag
- `a1802TOLA` series - Tenant statistics

**Scopes:**

```ruby
scope :active, -> { where(management_end_date: nil) }
scope :for_year, ->(year) {
  where('management_start_date <= ? AND (management_end_date IS NULL OR management_end_date >= ?)',
        Date.new(year, 12, 31), Date.new(year, 1, 1))
}
```

### 6. Settings Extensions

New organization-level settings:

| Key | Type | XBRL Element | Purpose |
|-----|------|--------------|---------|
| `activity_sales` | boolean | aACTIVE | Agency handles sales |
| `activity_rentals` | boolean | aACTIVERENTALS | Agency handles rentals |
| `activity_property_management` | boolean | aACTIVEPS | Agency does gestion locative |
| `staff_total` | integer | a11006 | Total staff count |
| `staff_compliance` | integer | aC11502 | Staff dedicated to compliance |
| `uses_external_compliance` | boolean | aC11508 | Outsourced compliance |
| `entity_legal_form` | enum | - | SAM/SARL/SCI/etc |
| `amsf_registration_number` | string | - | AMSF registration |

---

## CalculationEngine Extensions

New calculations to add:

```ruby
# Revenue calculations
def revenue_statistics
  {
    "a3802" => year_transactions.sales.sum(:commission_amount),
    "a3803" => year_transactions.rentals.sum(:commission_amount),
    "a3804" => managed_property_revenue,
    "a381"  => total_revenue
  }
end

def managed_property_revenue
  ManagedProperty.for_organization(organization).for_year(year).sum do |mp|
    mp.monthly_management_fee * months_active_in_year(mp, year)
  end
end

# Training calculations
def training_statistics
  trainings = Training.for_organization(organization).for_year(year)
  {
    "a3201" => trainings.exists? ? "Oui" : "Non",
    "a3202" => trainings.sum(:staff_count),
    "a3203" => trainings.count,
    # ... etc
  }
end

# Extended client statistics
def extended_client_statistics
  clients = organization.clients.kept
  {
    "a11301" => clients.where.not(rejected_at: nil).exists? ? "Oui" : "Non",
    "a11302" => clients.where.not(rejected_at: nil).count,
    "a1203"  => clients.where(due_diligence_level: 'REINFORCED').exists? ? "Oui" : "Non",
    # ... etc
  }
end
```

---

## UI: Submission Wizard

### Flow

```
Step 1: Activity Confirmation
├── Pre-filled from Settings
├── Sales: Yes/No
├── Rentals: Yes/No
├── Property Management: Yes/No
└── User confirms or updates

Step 2: Client Statistics Review
├── All values pre-calculated from CRM
├── Shows source: "Calculated from 47 clients"
├── Read-only with "Override" option
└── Year-over-year comparison shown

Step 3: Transaction Statistics Review
├── Pre-calculated from transactions
├── Purchases, Sales, Rentals
├── Values and counts
└── Review and confirm

Step 4: Training & Compliance Review
├── Training sessions from Training model
├── STR counts from str_reports
├── Staff statistics
└── Review and confirm

Step 5: Revenue Review
├── Sales revenue (from commission_amount)
├── Rental revenue (from commission_amount)
├── Management revenue (from ManagedProperty)
├── Total calculated
└── Review and confirm

Step 6: Policy Confirmation
├── Shows current Settings (105 aC* elements)
├── Highlights changes since last submission
├── Link to Settings page if updates needed
└── Quick confirm

Step 7: Review & Sign
├── Summary of all 323 elements
├── Signatory name & title input
├── Legal confirmation checkbox
└── [Generate XBRL] button
```

### UX Principles

1. **Pre-fill everything** - User sees values, not empty fields
2. **Confidence indicators** - Show calculation source
3. **Override sparingly** - Possible but not prominent
4. **Progress persistence** - Auto-save, allow resume
5. **Year-over-year comparison** - Help user spot anomalies

---

## Implementation Order

### Phase 1: Model Extensions
1. Add fields to Client model + migration
2. Add fields to Transaction model + migration
3. Add fields to BeneficialOwner model + migration
4. Create Training model + migration
5. Create ManagedProperty model + migration
6. Add new Settings keys to schema

### Phase 2: CalculationEngine
1. Add revenue calculations
2. Add training calculations
3. Add extended client statistics
4. Add extended transaction statistics
5. Add managed property statistics
6. Update populate_submission_values! to include all

### Phase 3: UI
1. Create submission wizard controller
2. Build step-by-step form views
3. Add review/confirm components
4. Add override functionality
5. Add progress persistence
6. Add year-over-year comparison

### Phase 4: Testing
1. Unit tests for new model validations
2. Unit tests for new calculations
3. Integration tests for wizard flow
4. XBRL generation tests with all 323 elements

---

## Success Criteria

- All 323 XBRL elements have a data source (calculated, settings, or derived)
- User can complete submission wizard with only review actions (no manual entry if CRM complete)
- Override capability exists for edge cases
- Year-over-year changes are visible for user validation
