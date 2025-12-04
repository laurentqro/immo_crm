# Data Model: AMSF Survey Data Capture

**Branch**: `013-amsf-data-capture` | **Date**: 2025-12-04

## Entity Relationship Overview

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  Organization   │──1:N──│     Client      │──1:N──│BeneficialOwner  │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        │                        │
        │                        │
       1:N                      1:N
        │                        │
        ▼                        ▼
┌─────────────────┐      ┌─────────────────┐
│   Submission    │      │   Transaction   │
└─────────────────┘      └─────────────────┘
        │
       1:N
        ▼
┌─────────────────┐
│SubmissionValue  │
└─────────────────┘

┌─────────────────┐      ┌─────────────────┐
│ManagedProperty  │──N:1──│     Client      │  (landlord)
└─────────────────┘      └─────────────────┘

┌─────────────────┐
│    Training     │──N:1──  Organization
└─────────────────┘
```

## Model Extensions

### Client (Extend)

**New Fields:**

| Field | Type | Null | Default | Constraints | XBRL Element |
|-------|------|------|---------|-------------|--------------|
| due_diligence_level | string | yes | - | STANDARD/SIMPLIFIED/REINFORCED | a1203, a1203D |
| simplified_dd_reason | text | yes | - | - | a1204S1 |
| relationship_end_reason | string | yes | - | CLIENT_REQUEST/AML_CONCERN/INACTIVITY/BUSINESS_DECISION/OTHER | a14001 |
| professional_category | string | yes | - | LEGAL/ACCOUNTANT/NOTARY/REAL_ESTATE/FINANCIAL/OTHER/NONE | a11602B, a11702B |
| source_of_funds_verified | boolean | yes | false | - | a13501B |
| source_of_wealth_verified | boolean | yes | false | - | a13601 series |

**Migration:**
```ruby
class AddComplianceFieldsToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :due_diligence_level, :string
    add_column :clients, :simplified_dd_reason, :text
    add_column :clients, :relationship_end_reason, :string
    add_column :clients, :professional_category, :string
    add_column :clients, :source_of_funds_verified, :boolean, default: false
    add_column :clients, :source_of_wealth_verified, :boolean, default: false

    add_index :clients, :due_diligence_level
    add_index :clients, :professional_category
  end
end
```

### Transaction (Extend)

**New Fields:**

| Field | Type | Null | Default | Constraints | XBRL Element |
|-------|------|------|---------|-------------|--------------|
| property_type | string | yes | - | RESIDENTIAL/COMMERCIAL/LAND/MIXED | a2113B, a2113W |
| is_new_construction | boolean | yes | false | - | a2114A, a2114AB |
| counterparty_is_pep | boolean | yes | false | - | a2110B, a2110W |
| counterparty_country | string(2) | yes | - | ISO 3166-1 alpha-2 | Geographic stats |
| rental_annual_value | decimal(15,2) | yes | - | >= 0 | a1106BRENTALS |
| rental_tenant_type | string | yes | - | NATURAL_PERSON/LEGAL_ENTITY | a1802TOLA series |

**Migration:**
```ruby
class AddComplianceFieldsToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :property_type, :string
    add_column :transactions, :is_new_construction, :boolean, default: false
    add_column :transactions, :counterparty_is_pep, :boolean, default: false
    add_column :transactions, :counterparty_country, :string, limit: 2
    add_column :transactions, :rental_annual_value, :decimal, precision: 15, scale: 2
    add_column :transactions, :rental_tenant_type, :string

    add_index :transactions, :property_type
    add_index :transactions, :counterparty_country
  end
end
```

### BeneficialOwner (Extend)

**New Fields:**

| Field | Type | Null | Default | Constraints | XBRL Element |
|-------|------|------|---------|-------------|--------------|
| source_of_wealth_verified | boolean | yes | false | - | a13601 series |
| identification_verified | boolean | yes | false | - | - |

**Migration:**
```ruby
class AddVerificationFieldsToBeneficialOwners < ActiveRecord::Migration[8.0]
  def change
    add_column :beneficial_owners, :source_of_wealth_verified, :boolean, default: false
    add_column :beneficial_owners, :identification_verified, :boolean, default: false
  end
end
```

### Submission (Extend)

**New Fields:**

| Field | Type | Null | Default | Constraints | FR |
|-------|------|------|---------|-------------|-----|
| current_step | integer | yes | 1 | 1-7 | FR-020 |
| locked_by_user_id | bigint | yes | - | FK to users | FR-029 |
| locked_at | datetime | yes | - | - | FR-029 |
| generated_at | datetime | yes | - | - | FR-024 |
| reopened_count | integer | no | 0 | >= 0 | FR-025 |

**Migration:**
```ruby
class AddLifecycleFieldsToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :current_step, :integer, default: 1
    add_column :submissions, :locked_by_user_id, :bigint
    add_column :submissions, :locked_at, :datetime
    add_column :submissions, :generated_at, :datetime
    add_column :submissions, :reopened_count, :integer, default: 0, null: false

    add_foreign_key :submissions, :users, column: :locked_by_user_id, on_delete: :nullify
    add_index :submissions, :locked_by_user_id
  end
end
```

### SubmissionValue (Extend)

**New Fields:**

| Field | Type | Null | Default | Constraints | FR |
|-------|------|------|---------|-------------|-----|
| override_reason | text | yes | - | Required if overridden | FR-018, FR-028 |
| override_user_id | bigint | yes | - | FK to users | FR-028 |
| previous_year_value | string | yes | - | - | FR-019 |

**Migration:**
```ruby
class AddOverrideTrackingToSubmissionValues < ActiveRecord::Migration[8.0]
  def change
    add_column :submission_values, :override_reason, :text
    add_column :submission_values, :override_user_id, :bigint
    add_column :submission_values, :previous_year_value, :string

    add_foreign_key :submission_values, :users, column: :override_user_id, on_delete: :nullify
    add_index :submission_values, :override_user_id
  end
end
```

## New Models

### ManagedProperty

**Purpose:** Track property management contracts (gestion locative) - primary revenue source for Monaco agencies.

| Field | Type | Null | Default | Constraints | XBRL Element |
|-------|------|------|---------|-------------|--------------|
| id | bigint | no | - | PK | - |
| organization_id | bigint | no | - | FK to organizations | - |
| client_id | bigint | no | - | FK to clients (landlord) | - |
| property_address | string | no | - | - | - |
| property_type | string | yes | RESIDENTIAL | RESIDENTIAL/COMMERCIAL | - |
| management_start_date | date | no | - | - | - |
| management_end_date | date | yes | - | - | - |
| monthly_rent | decimal(15,2) | yes | - | >= 0 | - |
| management_fee_percent | decimal(5,2) | yes | - | 0-100 | - |
| management_fee_fixed | decimal(15,2) | yes | - | >= 0 | - |
| tenant_name | string | yes | - | - | - |
| tenant_type | string | yes | - | NATURAL_PERSON/LEGAL_ENTITY | a1802TOLA |
| tenant_country | string(2) | yes | - | ISO 3166-1 alpha-2 | - |
| tenant_is_pep | boolean | no | false | - | - |
| notes | text | yes | - | - | - |
| created_at | datetime | no | - | - | - |
| updated_at | datetime | no | - | - | - |

**XBRL Elements Covered:**
- `a3804` - Management revenue (calculated from fees)
- `aACTIVEPS` - Activity flag (has any active properties?)
- `a1802TOLA` series - Tenant statistics

**Migration:**
```ruby
class CreateManagedProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :managed_properties do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :property_address, null: false
      t.string :property_type, default: 'RESIDENTIAL'
      t.date :management_start_date, null: false
      t.date :management_end_date
      t.decimal :monthly_rent, precision: 15, scale: 2
      t.decimal :management_fee_percent, precision: 5, scale: 2
      t.decimal :management_fee_fixed, precision: 15, scale: 2
      t.string :tenant_name
      t.string :tenant_type
      t.string :tenant_country, limit: 2
      t.boolean :tenant_is_pep, default: false, null: false
      t.text :notes
      t.timestamps
    end

    add_index :managed_properties, [:organization_id, :management_end_date],
              name: 'idx_managed_props_org_active'
    add_index :managed_properties, :client_id
    add_index :managed_properties, :management_start_date
  end
end
```

**Scopes:**
```ruby
scope :active, -> { where(management_end_date: nil) }
scope :active_in_year, ->(year) {
  year_start = Date.new(year, 1, 1)
  year_end = Date.new(year, 12, 31)
  where('management_start_date <= ? AND (management_end_date IS NULL OR management_end_date >= ?)',
        year_end, year_start)
}
scope :for_organization, ->(org) { where(organization: org) }
```

### Training

**Purpose:** Track AML/CFT staff training sessions.

| Field | Type | Null | Default | Constraints | XBRL Element |
|-------|------|------|---------|-------------|--------------|
| id | bigint | no | - | PK | - |
| organization_id | bigint | no | - | FK to organizations | - |
| training_date | date | no | - | - | - |
| training_type | string | no | - | INITIAL/REFRESHER/SPECIALIZED | a3201 |
| topic | string | no | - | AML_BASICS/PEP_SCREENING/STR_FILING/RISK_ASSESSMENT/SANCTIONS/KYC_PROCEDURES/OTHER | a3204 |
| provider | string | no | - | INTERNAL/EXTERNAL/AMSF/ONLINE | a3205 |
| staff_count | integer | no | - | > 0 | a3202 |
| duration_hours | decimal(4,2) | yes | - | >= 0 | a3303 |
| notes | text | yes | - | - | - |
| created_at | datetime | no | - | - | - |
| updated_at | datetime | no | - | - | - |

**XBRL Elements Covered:**
- `a3201` - Was training conducted? (Oui/Non)
- `a3202` - Staff trained count
- `a3203` - Number of sessions
- `a3204` - Topics covered
- `a3205` - Training providers used
- `a3301-a3303` - Training details

**Migration:**
```ruby
class CreateTrainings < ActiveRecord::Migration[8.0]
  def change
    create_table :trainings do |t|
      t.references :organization, null: false, foreign_key: true
      t.date :training_date, null: false
      t.string :training_type, null: false
      t.string :topic, null: false
      t.string :provider, null: false
      t.integer :staff_count, null: false
      t.decimal :duration_hours, precision: 4, scale: 2
      t.text :notes
      t.timestamps
    end

    add_index :trainings, [:organization_id, :training_date]
    add_index :trainings, :training_type
  end
end
```

**Scopes:**
```ruby
scope :for_year, ->(year) {
  where(training_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
}
scope :for_organization, ->(org) { where(organization: org) }
scope :by_type, ->(type) { where(training_type: type) }
```

## Enum Constants

Add to `app/models/concerns/amsf_constants.rb`:

```ruby
module AmsfConstants
  extend ActiveSupport::Concern

  # Existing constants...

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
end
```

## Validation Rules

### Client
```ruby
validates :due_diligence_level, inclusion: { in: DUE_DILIGENCE_LEVELS }, allow_blank: true
validates :simplified_dd_reason, presence: true, if: -> { due_diligence_level == 'SIMPLIFIED' }
validates :relationship_end_reason, inclusion: { in: RELATIONSHIP_END_REASONS }, allow_blank: true
validates :professional_category, inclusion: { in: PROFESSIONAL_CATEGORIES }, allow_blank: true
```

### Transaction
```ruby
validates :property_type, inclusion: { in: PROPERTY_TYPES }, allow_blank: true
validates :counterparty_country, format: { with: /\A[A-Z]{2}\z/ }, allow_blank: true
validates :rental_annual_value, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
validates :rental_tenant_type, inclusion: { in: TENANT_TYPES }, allow_blank: true
```

### ManagedProperty
```ruby
validates :property_address, presence: true
validates :management_start_date, presence: true
validates :property_type, inclusion: { in: MANAGED_PROPERTY_TYPES }, allow_blank: true
validates :monthly_rent, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
validates :management_fee_percent, numericality: { in: 0..100 }, allow_blank: true
validates :management_fee_fixed, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
validates :tenant_country, format: { with: /\A[A-Z]{2}\z/ }, allow_blank: true
validates :tenant_type, inclusion: { in: TENANT_TYPES }, allow_blank: true
validate :client_belongs_to_organization
validate :fee_structure_present

private

def fee_structure_present
  return if management_fee_percent.present? || management_fee_fixed.present?
  errors.add(:base, "Either percentage or fixed fee must be specified")
end
```

### Training
```ruby
validates :training_date, presence: true
validates :training_type, presence: true, inclusion: { in: TRAINING_TYPES }
validates :topic, presence: true, inclusion: { in: TRAINING_TOPICS }
validates :provider, presence: true, inclusion: { in: TRAINING_PROVIDERS }
validates :staff_count, presence: true, numericality: { greater_than: 0 }
validates :duration_hours, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
```

### SubmissionValue (Extended)
```ruby
validates :override_reason, presence: true, if: :overridden?
```

## Indexes

### Performance Indexes
```ruby
# For year-based queries on ManagedProperty
add_index :managed_properties, [:organization_id, :management_start_date, :management_end_date],
          name: 'idx_managed_props_date_range'

# For training statistics
add_index :trainings, [:organization_id, :training_date, :training_type],
          name: 'idx_trainings_stats'

# For override audit queries
add_index :submission_values, [:submission_id, :overridden],
          where: 'overridden = true',
          name: 'idx_sv_overridden'
```

## Data Integrity Constraints

### Foreign Keys
- ManagedProperty → Organization (cascade delete)
- ManagedProperty → Client (restrict delete)
- Training → Organization (cascade delete)
- SubmissionValue.override_user_id → User (nullify on delete)
- Submission.locked_by_user_id → User (nullify on delete)

### Business Rules (Application Level)
1. **One submission per org per year**: Enforced by unique index on (organization_id, year)
2. **Client belongs to same org**: Validated in model for ManagedProperty → Client
3. **Fee structure required**: Either percent or fixed fee must be present
4. **Override requires reason**: validated when overridden = true
