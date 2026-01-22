# Data Model: AMSF Survey Gem Migration

**Feature**: 016-amsf-gem-migration
**Date**: 2026-01-22

## Entity Overview

This migration does not introduce new database entities. Instead, it maps existing CRM models to gem value objects.

```
┌─────────────────────────────────────────────────────────────────┐
│                         CRM Layer (Persisted)                    │
├─────────────────────────────────────────────────────────────────┤
│  Organization ──────┬──────> Submission ────> SubmissionValue   │
│       │             │             │                  │           │
│       │             │             │                  │           │
│  [has_many          │       [year, status]    [element_name,    │
│   clients,          │                          value, source]   │
│   transactions]     │                                           │
└─────────────────────┼───────────────────────────────────────────┘
                      │
                      │ on-demand conversion
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Gem Layer (Value Objects)                   │
├─────────────────────────────────────────────────────────────────┤
│  Questionnaire ────> Section ────> Field                         │
│       │                               │                          │
│       │                               │                          │
│  [industry,          [id, name]  [id, type, label,              │
│   year,                            gate?, visible?]              │
│   taxonomy_namespace]                                            │
│                                                                  │
│  Submission ────────────────────────────────────────────────────│
│  [entity_id, period, data{field_id => value}]                   │
│       │                                                          │
│       ▼                                                          │
│  ValidationResult ───> ValidationError                           │
│  [valid?, errors]      [field, rule, message]                   │
└─────────────────────────────────────────────────────────────────┘
```

## Entity Mappings

### CRM → Gem Mapping

| CRM Entity | Gem Entity | Notes |
|------------|------------|-------|
| `Submission` (AR) | `AmsfSurvey::Submission` | Gem submission is ephemeral, AR is persisted |
| `SubmissionValue` | `submission[field_id]` | Values transferred to gem submission |
| `Organization.rci_number` | `submission.entity_id` | Unique identifier for XBRL |
| `Submission.year` | `submission.year` | Taxonomy year |
| N/A | `Questionnaire` | Loaded from gem |
| `Xbrl::TaxonomyElement` | `AmsfSurvey::Field` | Gem replaces custom class |
| `Xbrl::Taxonomy.elements_by_section` | `questionnaire.sections` | Gem replaces custom code |

### Field Type Mapping

| Current Type | Gem Type | Value Format |
|--------------|----------|--------------|
| `:boolean` | `:boolean` | "Oui" / "Non" (strings) |
| `:integer` | `:integer` | Ruby Integer |
| `:monetary` | `:monetary` | BigDecimal |
| `:string` | `:string` | Ruby String |
| `:decimal` | `:percentage` | BigDecimal (0-100) |
| N/A | `:enum` | String from `valid_values` |

### Source Type Mapping

| Current Source | Gem Source Type | Description |
|----------------|-----------------|-------------|
| "calculated" | `:prefillable` | Auto-computed from CRM data |
| "from_settings" | `:prefillable` | From organization settings |
| "manual" | `:entry_only` | User-entered override |
| N/A | `:computed` | Derived fields (sum, etc.) |

## Existing Models (No Changes)

### Submission (ActiveRecord)

```ruby
# app/models/submission.rb - NO CHANGES
class Submission < ApplicationRecord
  belongs_to :organization
  has_many :submission_values, dependent: :destroy

  validates :year, presence: true,
                   numericality: { greater_than_or_equal_to: 2000 }
  validates :year, uniqueness: { scope: :organization_id }

  # Existing lifecycle methods preserved
  def status_label
    # ...
  end
end
```

### SubmissionValue (ActiveRecord)

```ruby
# app/models/submission_value.rb - NO CHANGES
class SubmissionValue < ApplicationRecord
  belongs_to :submission

  validates :element_name, presence: true
  validates :element_name, uniqueness: { scope: :submission_id }

  # source: calculated | from_settings | manual
  # overridden?: true if source changed from calculated
  # confirmed?: true if user reviewed
end
```

## Gem Value Objects (New)

### Questionnaire

```ruby
# From gem - accessed via AmsfSurvey.questionnaire(industry:, year:)
# Immutable, cached per (industry, year)

questionnaire.industry          # :real_estate
questionnaire.year              # 2025
questionnaire.sections          # Array<Section>
questionnaire.fields            # Array<Field>
questionnaire.field(:a1101)     # Field or nil
questionnaire.taxonomy_namespace # String for XBRL
```

### Field

```ruby
# From gem - accessed via questionnaire.field(id) or section.fields

field.id           # :a1101 (Symbol)
field.name         # :a1101 (may differ from id if semantic mapping exists)
field.type         # :boolean | :integer | :string | :monetary | :enum | :percentage
field.source_type  # :computed | :prefillable | :entry_only
field.label        # "Nombre total de clients" (French)
field.gate?        # true if controls other fields
field.visible?(data) # true if gate dependencies satisfied
field.required?    # true if not computed
field.cast(value)  # type-cast value
```

### Submission (Gem)

```ruby
# From gem - created via AmsfSurvey.build_submission(...)
# Value object, not persisted

submission.industry    # :real_estate
submission.year        # 2025
submission.entity_id   # "RCI12345"
submission.period      # Date
submission.data        # Hash{Symbol => Object} (frozen copy)
submission[:field_id]  # Get value
submission[:field_id] = value  # Set value (auto-cast)
submission.complete?   # Boolean
submission.missing_fields  # Array<Symbol>
```

### ValidationResult

```ruby
# From gem - returned by AmsfSurvey.validate(submission)

result.valid?    # Boolean
result.errors    # Array<ValidationError>
result.warnings  # Array<ValidationError>
```

### ValidationError

```ruby
# From gem - contained in ValidationResult

error.field      # :a1101 (Symbol)
error.rule       # :presence | :enum | :range
error.message    # Localized message (French by default)
error.severity   # :error | :warning
error.context    # Hash with additional info
```

## Data Flow

### Value Population Flow

```
Organization CRM Data
        │
        ▼
CalculationEngine.calculate_all
        │
        ├─── client_statistics
        ├─── transaction_statistics
        ├─── etc.
        │
        ▼
SubmissionValue records (source: "calculated")
        │
        ├─── Settings values (source: "from_settings")
        ├─── Manual overrides (source: "manual")
        │
        ▼
Gem Submission.data (populated from SubmissionValue)
```

### XBRL Generation Flow

```
AR Submission
     │
     ▼
SubmissionBuilder.build
     │
     ├─── Creates gem Submission
     ├─── Populates from SubmissionValue
     │
     ▼
AmsfSurvey.to_xbrl(submission)
     │
     ├─── Generator builds DOM
     ├─── Uses taxonomy_namespace
     ├─── Creates context element
     ├─── Creates fact elements
     │
     ▼
XBRL XML String
```

### Validation Flow

```
Gem Submission
     │
     ▼
AmsfSurvey.validate(submission)
     │
     ├─── Presence checks (required fields)
     ├─── Enum validation (valid_values)
     ├─── Range validation (min/max)
     │
     ▼
ValidationResult
     │
     ├─── If valid? && arelle_enabled
     │         │
     │         ▼
     │    External Arelle validation
     │
     ▼
Final validation result
```

## Validation Rules

### Presence Validation
- Required fields: All non-computed, visible fields
- Hidden fields: Skipped (gate not satisfied)
- Empty check: `nil` values are invalid

### Enum Validation
- Fields with `valid_values` must have value in list
- Boolean fields: Must be "Oui" or "Non"

### Range Validation
- Percentage fields: 0-100
- Custom ranges from taxonomy min/max
- Only applies to numeric types

## Migration Considerations

### No Schema Changes Required

The existing database schema supports this migration without modification:
- `submission_values.element_name` stores XBRL codes (compatible with gem)
- `submission_values.value` stores string representation (gem casts on read)
- `submission_values.source` tracks origin (unchanged)

### Data Compatibility

| Existing Data | Gem Expectation | Compatible? |
|---------------|-----------------|-------------|
| `element_name: "a1101"` | `field.id: :a1101` | Yes (string to symbol) |
| `value: "150"` | `Integer` | Yes (gem casts) |
| `value: "Oui"` | `"Oui"` | Yes (already string) |
| `value: "5000.50"` | `BigDecimal` | Yes (gem casts) |
