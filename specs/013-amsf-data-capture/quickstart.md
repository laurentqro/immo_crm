# Quickstart Guide: AMSF Survey Data Capture

**Branch**: `013-amsf-data-capture` | **Date**: 2025-12-04

## Prerequisites

```bash
# Ensure you're on the correct branch
git checkout 013-amsf-data-capture

# Install dependencies
bundle install

# Ensure database is up to date with existing migrations
bin/rails db:migrate
```

## Step 1: Run New Migrations

After implementing the migrations from `data-model.md`:

```bash
# Generate migrations (if not already created)
bin/rails generate migration AddComplianceFieldsToClients \
  due_diligence_level:string \
  simplified_dd_reason:text \
  relationship_end_reason:string \
  professional_category:string \
  source_of_funds_verified:boolean \
  source_of_wealth_verified:boolean

bin/rails generate migration AddComplianceFieldsToTransactions \
  property_type:string \
  is_new_construction:boolean \
  counterparty_is_pep:boolean \
  counterparty_country:string \
  rental_annual_value:decimal \
  rental_tenant_type:string

bin/rails generate migration AddVerificationFieldsToBeneficialOwners \
  source_of_wealth_verified:boolean \
  identification_verified:boolean

bin/rails generate migration AddLifecycleFieldsToSubmissions \
  current_step:integer \
  locked_by_user_id:bigint \
  locked_at:datetime \
  generated_at:datetime \
  reopened_count:integer

bin/rails generate migration AddOverrideTrackingToSubmissionValues \
  override_reason:text \
  override_user_id:bigint \
  previous_year_value:string

bin/rails generate model ManagedProperty \
  organization:references \
  client:references \
  property_address:string \
  property_type:string \
  management_start_date:date \
  management_end_date:date \
  monthly_rent:decimal \
  management_fee_percent:decimal \
  management_fee_fixed:decimal \
  tenant_name:string \
  tenant_type:string \
  tenant_country:string \
  tenant_is_pep:boolean \
  notes:text

bin/rails generate model Training \
  organization:references \
  training_date:date \
  training_type:string \
  topic:string \
  provider:string \
  staff_count:integer \
  duration_hours:decimal \
  notes:text

# Run migrations
bin/rails db:migrate
```

## Step 2: Add Constants to AmsfConstants

Edit `app/models/concerns/amsf_constants.rb`:

```ruby
# Add these constants after existing ones

# Due Diligence Levels (FR-001)
DUE_DILIGENCE_LEVELS = %w[STANDARD SIMPLIFIED REINFORCED].freeze

# Relationship End Reasons
RELATIONSHIP_END_REASONS = %w[
  CLIENT_REQUEST AML_CONCERN INACTIVITY BUSINESS_DECISION OTHER
].freeze

# Professional Categories (FR-002)
PROFESSIONAL_CATEGORIES = %w[
  LEGAL ACCOUNTANT NOTARY REAL_ESTATE FINANCIAL OTHER NONE
].freeze

# Property Types (FR-008)
PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL LAND MIXED].freeze

# Tenant Types (FR-006)
TENANT_TYPES = %w[NATURAL_PERSON LEGAL_ENTITY].freeze

# Training Types (FR-007)
TRAINING_TYPES = %w[INITIAL REFRESHER SPECIALIZED].freeze

# Training Topics
TRAINING_TOPICS = %w[
  AML_BASICS PEP_SCREENING STR_FILING RISK_ASSESSMENT
  SANCTIONS KYC_PROCEDURES OTHER
].freeze

# Training Providers
TRAINING_PROVIDERS = %w[INTERNAL EXTERNAL AMSF ONLINE].freeze

# Managed Property Types
MANAGED_PROPERTY_TYPES = %w[RESIDENTIAL COMMERCIAL].freeze
```

## Step 3: Verify Setup

```bash
# Run tests to ensure nothing is broken
bin/rails test

# Start console and verify models
bin/rails console

# In console:
ManagedProperty.new.valid?  # Should show validation errors for required fields
Training.new.valid?         # Should show validation errors for required fields
Client.columns.map(&:name)  # Should include new compliance fields
```

## Step 4: Seed Test Data (Development)

```ruby
# In rails console or db/seeds.rb

org = Organization.first

# Create sample managed properties
landlord = org.clients.where(client_type: 'PP').first
ManagedProperty.create!(
  organization: org,
  client: landlord,
  property_address: "4 Avenue de Monte-Carlo, Monaco",
  property_type: "RESIDENTIAL",
  management_start_date: Date.new(2024, 1, 1),
  monthly_rent: 5000,
  management_fee_percent: 8.0,
  tenant_name: "Tenant Name",
  tenant_type: "NATURAL_PERSON",
  tenant_country: "FR"
)

# Create sample training record
Training.create!(
  organization: org,
  training_date: Date.new(2025, 3, 15),
  training_type: "REFRESHER",
  topic: "AML_BASICS",
  provider: "EXTERNAL",
  staff_count: 5,
  duration_hours: 4.0
)

# Update a client with new compliance fields
client = org.clients.first
client.update!(
  due_diligence_level: "STANDARD",
  professional_category: "NONE",
  source_of_funds_verified: true
)
```

## Step 5: Test Wizard Flow

1. Start development server: `bin/dev`
2. Log in as a user with compliance access
3. Navigate to Submissions
4. Create a new submission for current year
5. Walk through all 7 steps

## Key Files to Implement

### Models (in order)
1. `app/models/managed_property.rb` - NEW
2. `app/models/training.rb` - NEW
3. `app/models/client.rb` - Add validations for new fields
4. `app/models/transaction.rb` - Add validations for new fields
5. `app/models/submission.rb` - Add lifecycle methods

### Services
1. `app/services/calculation_engine.rb` - Extend with new calculations
2. `app/services/year_over_year_comparator.rb` - NEW

### Controller
1. `app/controllers/submission_steps_controller.rb` - Extend for 7 steps

### Views
1. `app/views/submission_steps/step_1.html.erb` - Activity confirmation
2. `app/views/submission_steps/step_2.html.erb` - Client statistics
3. `app/views/submission_steps/step_3.html.erb` - Transaction statistics
4. `app/views/submission_steps/step_4.html.erb` - Training & compliance
5. `app/views/submission_steps/step_5.html.erb` - Revenue review
6. `app/views/submission_steps/step_6.html.erb` - Policy confirmation
7. `app/views/submission_steps/step_7.html.erb` - Review & sign

### Components
1. `app/components/statistic_card_component.rb` - Display single stat
2. `app/components/statistic_group_component.rb` - Group related stats

### Tests
1. `test/models/managed_property_test.rb`
2. `test/models/training_test.rb`
3. `test/services/calculation_engine_test.rb` - Extend
4. `test/services/year_over_year_comparator_test.rb`
5. `test/controllers/submission_steps_controller_test.rb` - Extend
6. `test/system/submission_wizard_test.rb`

## Common Issues

### Migration fails with existing data
If clients/transactions have invalid data for new enum fields:
```ruby
# Set defaults before adding constraints
Client.where(due_diligence_level: nil).update_all(due_diligence_level: 'STANDARD')
```

### Tests fail after model changes
Run: `bin/rails db:test:prepare` to sync test database schema

### RuboCop failures
Run: `bin/rubocop -a` to auto-fix style issues
