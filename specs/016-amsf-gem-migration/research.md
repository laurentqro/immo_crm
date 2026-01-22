# Research: AMSF Survey Gem Migration

**Feature**: 016-amsf-gem-migration
**Date**: 2026-01-22

## Gem API Reference

### Core Entry Points

The `amsf_survey` gem provides four main entry points:

| Method | Purpose | Returns |
|--------|---------|---------|
| `AmsfSurvey.questionnaire(industry:, year:)` | Load questionnaire structure | `Questionnaire` |
| `AmsfSurvey.build_submission(industry:, year:, entity_id:, period:)` | Create submission value object | `Submission` |
| `AmsfSurvey.validate(submission)` | Ruby-native validation | `ValidationResult` |
| `AmsfSurvey.to_xbrl(submission, **options)` | Generate XBRL XML | `String` |

### Questionnaire API

```ruby
questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)

questionnaire.fields          # Array<Field> - all fields across sections
questionnaire.sections        # Array<Section> - logical groupings
questionnaire.field(:a1101)   # Field - lookup by XBRL code
questionnaire.field(:total_clients)  # Field - lookup by semantic name
questionnaire.field_count     # Integer - total fields (~600)
questionnaire.taxonomy_namespace  # String - for XBRL generation
```

### Field API

```ruby
field.id             # Symbol - semantic field name
field.name           # Symbol - XBRL code (e.g., :a1101)
field.label          # String - French label
field.type           # Symbol - :boolean, :integer, :string, :monetary, :enum, :percentage
field.source_type    # Symbol - :computed, :prefillable, :entry_only
field.gate?          # Boolean - is this a gate question?
field.visible?(data) # Boolean - check gate dependencies
field.required?      # Boolean - true if not computed
field.cast(value)    # Object - type-cast a value
field.valid_values   # Array or nil - enum options
field.depends_on     # Hash - gate dependencies
```

### Submission API

The gem's `Submission` is a value object, not an ActiveRecord model:

```ruby
submission = AmsfSurvey.build_submission(
  industry: :real_estate,
  year: 2025,
  entity_id: "RCI12345",
  period: Date.new(2025, 12, 31)
)

submission[:total_clients] = 150       # Set field value (auto-cast)
submission[:total_clients]             # Get field value
submission.data                        # Hash - frozen copy of all values
submission.complete?                   # Boolean - all required visible fields filled
submission.missing_fields              # Array<Symbol> - IDs of missing required fields
submission.completion_percentage       # Float - 0.0 to 100.0
```

### Validation API

```ruby
result = AmsfSurvey.validate(submission)

result.valid?        # Boolean
result.errors        # Array<ValidationError>
result.warnings      # Array<ValidationError>

# Each error has:
error.field          # Symbol - field ID
error.rule           # Symbol - :presence, :enum, :range
error.message        # String - localized message
error.severity       # Symbol - :error or :warning
error.context        # Hash - additional context
```

Locale support:
```ruby
# Default is French (:fr) for Monaco context
result = AmsfSurvey.validate(submission)

# English for development
result = Validator.validate(submission, locale: :en)
```

### XBRL Generation API

```ruby
xml = AmsfSurvey.to_xbrl(submission)
xml = AmsfSurvey.to_xbrl(submission, pretty: true)
xml = AmsfSurvey.to_xbrl(submission, include_empty: false)
```

Options:
- `pretty: true` - Output indented XML (default: false)
- `include_empty: false` - Omit nil fields (default: true)

## Current immo_crm Code Mapping

### Files to Delete (Gem Replaces)

| Current File | Lines | Gem Replacement |
|--------------|-------|-----------------|
| `app/models/xbrl/taxonomy.rb` | ~250 | `AmsfSurvey.questionnaire()` |
| `app/models/xbrl/taxonomy_element.rb` | ~50 | `Field` class |
| `app/models/xbrl/survey.rb` | ~100 | `Questionnaire.sections` |
| `config/initializers/xbrl_taxonomy.rb` | ~10 | New initializer |
| `app/views/submissions/show.xml.erb` | ~100 | `AmsfSurvey.to_xbrl()` |
| `docs/taxonomy/` | N/A | Gem includes taxonomy |
| `config/xbrl_short_labels.yml` | ~50 | Gem semantic mappings |

### Files to Refactor

| Current File | Change Required |
|--------------|-----------------|
| `app/models/xbrl/element_manifest.rb` | Use `questionnaire.field()` instead of `Taxonomy.element()` |
| `app/services/submission_builder.rb` | Create gem `Submission` for validation/generation |
| `app/services/submission_renderer.rb` | Use `AmsfSurvey.to_xbrl()` for XBRL output |
| `app/services/calculation_engine.rb` | Keep as-is (XBRL codes still valid) |
| `app/services/validation_service.rb` | Add gem validation before/instead of external |

## Integration Pattern

### Decision: Dual Submission Pattern

**Rationale**: The gem's `Submission` is a value object for generation/validation, not persistence. The CRM needs ActiveRecord `Submission` for lifecycle tracking, audit trails, and organization scoping.

**Approach**:
1. Keep ActiveRecord `Submission` for persistence
2. Create gem `Submission` on-demand for validation/generation
3. Sync data from `SubmissionValue` records to gem submission

```ruby
# SubmissionBuilder pattern
class SubmissionBuilder
  def build
    # 1. Create/find AR submission (for persistence)
    @submission = Submission.find_or_create_by!(organization: org, year: year)

    # 2. Populate calculated values
    populate_values

    # 3. Build gem submission (for generation/validation)
    @gem_submission = create_gem_submission
  end

  def gem_submission
    @gem_submission
  end

  def validate
    AmsfSurvey.validate(@gem_submission)
  end

  def to_xbrl
    AmsfSurvey.to_xbrl(@gem_submission, pretty: true)
  end

  private

  def create_gem_submission
    sub = AmsfSurvey.build_submission(
      industry: :real_estate,
      year: @submission.year,
      entity_id: @submission.organization.rci_number,
      period: Date.new(@submission.year, 12, 31)
    )

    # Populate from stored values
    @submission.submission_values.each do |sv|
      sub[sv.element_name.to_sym] = sv.value
    end

    sub
  end
end
```

### Decision: Field Name Strategy

**Rationale**: The gem supports lookup by both semantic name (`:total_clients`) and XBRL code (`:a1101`). The current CRM uses XBRL codes throughout.

**Approach**: Continue using XBRL codes for now.
- CalculationEngine already uses XBRL codes
- SubmissionValue stores `element_name` as XBRL code
- Gem's `questionnaire.field(:a1101)` works with codes
- Future: Could adopt semantic names for readability

### Decision: Validation Strategy

**Rationale**: The gem provides fast Ruby-native validation. External Arelle validation is authoritative but slow.

**Approach**: Layer validation:
1. Run gem validation first (fast, catches most errors)
2. Only call external Arelle if gem validation passes and config enabled
3. Display gem validation errors in French (default locale)

```ruby
def validate
  gem_result = AmsfSurvey.validate(@gem_submission)
  return gem_result unless gem_result.valid?

  if Rails.configuration.x.arelle_validation_enabled
    arelle_result = external_arelle_validation(@gem_submission)
    merge_results(gem_result, arelle_result)
  else
    gem_result
  end
end
```

## Alternatives Considered

### Alternative 1: Replace SubmissionValue with Gem Data

**Rejected because**:
- Loses audit trail (who changed what, when)
- Loses source tracking (calculated vs manual)
- Requires schema changes for multi-submission comparison
- Current pattern works well

### Alternative 2: Full Semantic Field Names

**Rejected because**:
- Would require updating all CalculationEngine formulas
- Would require migration of existing SubmissionValue records
- Minimal benefit since gem accepts both formats
- Can adopt incrementally later if needed

### Alternative 3: Remove External Arelle Validation

**Rejected because**:
- External validation is authoritative for regulatory compliance
- Gem validation is fast but may miss edge cases
- Keep as optional layer for production use

## Risk Mitigations

### Risk: XBRL Output Differences

**Mitigation**: Create comparison test that generates XBRL with both old and new code for same data, compares normalized XML. Must pass before deleting old code.

### Risk: Gate Logic Mismatch

**Mitigation**: The gem's `field.visible?(data)` handles gate dependencies. Verify against current view logic in ElementManifest.

### Risk: Type Casting Differences

**Mitigation**: Gem's `TypeCaster` handles Oui/Non strings, BigDecimal for monetary, integers. Review current value storage to ensure compatibility.

## Performance Considerations

- Gem questionnaire is cached per (industry, year) - fast repeat access
- Validation is single-pass through fields - O(n) complexity
- XBRL generation builds DOM once - predictable memory usage
- No network calls for validation (unless Arelle enabled)

## Dependencies

### New Gems

```ruby
# Gemfile additions
gem 'amsf_survey', path: '../amsf_survey/amsf_survey'
gem 'amsf_survey-real_estate', path: '../amsf_survey/amsf_survey-real_estate'
```

Or once published:
```ruby
gem 'amsf_survey'
gem 'amsf_survey-real_estate'
```

### Initializer

```ruby
# config/initializers/amsf_survey.rb
require 'amsf_survey/real_estate'

Rails.application.config.after_initialize do
  q = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
  Rails.logger.info "AMSF Survey loaded: #{q.field_count} fields"
end
```

## Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Submission pattern | Dual (AR + Gem) | Preserve persistence and audit trail |
| Field names | XBRL codes | Maintain compatibility, migrate later if needed |
| Validation | Gem first, Arelle optional | Fast feedback with authoritative backup |
| XBRL generation | Gem only | Replace ERB template entirely |
| Testing | Comparison test | Verify output parity before deletion |
