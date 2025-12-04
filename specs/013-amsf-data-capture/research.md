# Phase 0 Research: AMSF Survey Data Capture

**Branch**: `013-amsf-data-capture` | **Date**: 2025-12-04

## Existing Codebase Analysis

### Models to Extend

| Model | Current Fields | Fields to Add | XBRL Elements |
|-------|----------------|---------------|---------------|
| **Client** | name, client_type, is_pep, risk_level, nationality, residence_status, rejected_at | due_diligence_level, simplified_dd_reason, relationship_end_reason, professional_category, source_of_funds_verified, source_of_wealth_verified | a1203, a1203D, a1204S, a14001, a11602B, a13501B, a13601 series |
| **Transaction** | transaction_type, transaction_value, payment_method, property_country | property_type, is_new_construction, counterparty_is_pep, counterparty_country, rental_annual_value, rental_tenant_type | a2113B/W, a2114A, a2110B/W, a2114AB, a1106BRENTALS |
| **BeneficialOwner** | name, ownership_pct, control_type, is_pep | source_of_wealth_verified, identification_verified | a13601 series |
| **Submission** | status, year, signatory_name/title, taxonomy_version | current_step, locked_by_user_id, locked_at, generated_at, reopened_count | FR-020, FR-024, FR-025, FR-029 |
| **SubmissionValue** | element_name, value, source, overridden, confirmed_at | override_reason, override_user_id, previous_year_value | FR-018, FR-019, FR-028 |

### New Models Required

| Model | Purpose | Key Fields |
|-------|---------|------------|
| **ManagedProperty** | Track property management contracts (gestion locative) | organization_id, client_id (landlord), property_address, property_type, management_start_date, management_end_date, monthly_rent, management_fee_percent, management_fee_fixed, tenant_name, tenant_type, tenant_country, tenant_is_pep |
| **Training** | Track AML/CFT staff training sessions | organization_id, training_date, training_type, topic, provider, staff_count, duration_hours, notes |

### Existing Patterns to Follow

#### Soft Deletes (Discard gem)
```ruby
include Discard::Model
self.discard_column = :deleted_at
scope :kept, -> { undiscarded }  # automatically provided
```

#### Account Scoping
```ruby
scope :for_organization, ->(org) { where(organization: org) }
belongs_to :organization
```

#### AmsfConstants Concern
All enum values centralized in `app/models/concerns/amsf_constants.rb`

#### Auditable Concern
```ruby
include Auditable
# Automatically logs create/update/destroy via AuditLog
```

#### Pundit Policies
```ruby
# app/policies/submission_policy.rb
def complete?
  user_is_admin_or_compliance_officer?
end
```

### Controller Patterns

#### SubmissionStepsController (Existing Wizard)
- Currently 4 steps: Review Aggregates → Confirm Policies → Fresh Questions → Validate & Download
- Uses `step` param for navigation
- Stores progress via SubmissionValue records
- Template naming: `step_1.html.erb`, `step_2.html.erb`, etc.

#### Extension Approach
Extend to 7 steps per design document:
1. Activity Confirmation
2. Client Statistics Review
3. Transaction Statistics Review
4. Training & Compliance Review
5. Revenue Review
6. Policy Confirmation
7. Review & Sign

### CalculationEngine Patterns

Current implementation at `app/services/calculation_engine.rb:1-212`:
- Initialized with submission instance
- `calculate_all` returns Hash of element_name → value
- `populate_submission_values!` persists to SubmissionValue
- Respects `overridden?` flag - doesn't overwrite user edits

Extension points for new calculations:
```ruby
# Add to calculate_all
def calculate_all
  {}.merge(
    # existing...
    managed_property_statistics,
    training_statistics,
    extended_client_statistics,
    revenue_statistics
  )
end
```

### View Component Patterns

Existing components in `app/components/`:
- `modal_component.rb` - Dialog overlays
- `tabs_component.rb` - Tabbed navigation
- `toast_component.rb` - Flash messages

New components needed:
- `StatisticCardComponent` - Display single calculated value with source
- `StatisticGroupComponent` - Group related statistics
- `YearComparisonComponent` - Show YoY change with highlighting

## Technology Decisions

### Wizard Navigation
**Decision**: Extend existing SubmissionStepsController pattern
**Rationale**: Maintains consistency, reuses authorization, follows established patterns

### Year-over-Year Comparison
**Decision**: New service `YearOverYearComparator`
**Rationale**: Separates concerns, testable, reusable

```ruby
class YearOverYearComparator
  def initialize(current_submission, previous_submission = nil)
  def comparison_for(element_name)  # → { previous: X, current: Y, change_pct: Z }
  def significant_changes(threshold: 25)  # → Array of elements with >25% change
end
```

### Submission Lifecycle
**Current states**: draft → in_review → validated → completed
**Extension**: Add "generated" state between validated and completed

Per FR-024/FR-025:
- After XBRL generation: status = "generated", locked = true
- Reopening: status = "draft", reopened_count += 1, locked = false

### Override Audit Trail
**Decision**: Add fields to SubmissionValue
```ruby
# When value is overridden:
override_reason: "Manual adjustment per accountant"
override_user_id: 42
overridden: true
# Original value preserved in calculation (can revert)
```

### Property Management Revenue Calculation
**Algorithm**:
```ruby
def managed_property_revenue(year)
  ManagedProperty.active_in_year(year).sum do |mp|
    months_active = months_in_range(
      [mp.management_start_date, Date.new(year, 1, 1)].max,
      [mp.management_end_date || Date.new(year, 12, 31), Date.new(year, 12, 31)].min
    )
    monthly_fee(mp) * months_active
  end
end

def monthly_fee(mp)
  mp.management_fee_fixed || (mp.monthly_rent * mp.management_fee_percent / 100)
end
```

## Risk Analysis

| Risk | Mitigation |
|------|------------|
| 323 elements scope creep | Focus on spec's 35 FRs, defer unmapped elements |
| Migration complexity | Separate migrations per model, reversible |
| Wizard UX complexity | Progressive disclosure, step-by-step validation |
| YoY calculation edge cases | Handle missing prior year gracefully |

## Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| discard | 1.3+ | Soft deletes (existing) |
| pundit | 2.3+ | Authorization (existing) |
| turbo-rails | 2.0+ | Wizard navigation (existing) |
| iso_country_codes | - | Country validation (existing via Client model) |

## Outstanding Questions

None - all clarifications addressed in spec.md Clarifications section:
- Authorization: Compliance officer/admin only for submission
- Locking: Submissions lock after XBRL generation, can reopen
- Concurrency: Single user editing at a time
- Uniqueness: One submission per org per year
- Validation: Continuous warnings, block at generation
