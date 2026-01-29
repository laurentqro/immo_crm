# Migration Guide: immo_crm → amsf_survey gem (COMPLETED)

> **Migration Status:** COMPLETED (January 2026)
>
> The gem integration is complete. This document is preserved for reference.

## What Was Done

### Phase 1: Gem Installation
- Added `amsf_survey` and `amsf_survey-real_estate` gems to Gemfile
- Created `config/initializers/amsf_survey.rb` to load and verify gem

### Phase 2: XBRL Generation via Gem
- Refactored `SubmissionBuilder` to create gem submissions
- Refactored `SubmissionRenderer` to generate XBRL via gem for supported years
- Added `gem_submission` accessor for direct gem access
- Maintained backward compatibility for unsupported years via ERB template

### Phase 3: Validation via Gem
- Added `AmsfSurvey.validate()` integration in `SubmissionBuilder#validate`
- Implemented layered validation: gem first, optional Arelle
- Added `AmsfValidationConfig.arelle_enabled?` configuration toggle
- Environment variable: `ARELLE_VALIDATION_ENABLED` (default: false in dev/test)

### Phase 4: Questionnaire Metadata via Gem
- Updated `ElementManifest` to provide gem questionnaire access
- Added `field()`, `all_fields`, `fields_by_section` methods
- Added gate visibility checking via `field_visible?`

### Phase 5: Multi-Year Support
- Verified gem handles multiple taxonomy years (currently 2025)
- Graceful fallback for unsupported years

## What Was NOT Deleted

The original migration plan proposed deleting ~500 lines of code. After analysis, these files are still in use:

| File | Reason Kept |
|------|-------------|
| `app/models/xbrl/taxonomy.rb` | Used by xbrl_helper.rb, submission_value.rb for labels |
| `app/models/xbrl/taxonomy_element.rb` | Required by Taxonomy |
| `app/models/xbrl/survey.rb` | Used by survey_reviews_controller.rb |
| `config/initializers/xbrl_taxonomy.rb` | Loads taxonomy on boot |
| `app/views/submissions/show.xml.erb` | Fallback for unsupported years |
| `docs/taxonomy/` | Taxonomy XSD/XML files for Taxonomy class |
| `config/xbrl_short_labels.yml` | Short labels for UI |

## Current Architecture

```
amsf_survey gem                    immo_crm (your code)
─────────────────                  ────────────────────
AmsfSurvey.questionnaire ◄─────── ElementManifest.questionnaire
AmsfSurvey.validate ◄──────────── SubmissionBuilder.validate
AmsfSurvey.to_xbrl ◄───────────── SubmissionBuilder.generate_xbrl
                                  SubmissionRenderer.to_xbrl
                                  │
                                  ├── Xbrl::Taxonomy (still used for labels)
                                  ├── Xbrl::Survey (still used for sections)
                                  └── CalculationEngine (unchanged)
```

## Usage Examples

```ruby
# Build submission with gem integration
builder = SubmissionBuilder.new(organization, year: 2025)
result = builder.build

# Access gem submission
gem_submission = builder.gem_submission
gem_submission[:a1101]  # => "42"

# Validate via gem
validation = builder.validate
validation.valid?    # => true/false
validation.errors    # => Array of errors

# Generate XBRL via gem
xbrl = builder.generate_xbrl

# Optional: External Arelle validation
arelle_result = builder.validate_with_arelle

# Layered validation (both gem and Arelle)
layered = builder.validate_layered
layered[:gem]     # => AmsfSurvey::ValidationResult
layered[:arelle]  # => ValidationService::Result (if enabled)
layered[:valid]   # => combined validity
```

## Future Cleanup (Optional)

To fully remove the old taxonomy code, you would need to:

1. Update `app/helpers/xbrl_helper.rb` to use gem field labels
2. Update `app/models/submission_value.rb` to use gem for descriptions
3. Update `survey_reviews_controller.rb` to use gem sections
4. Remove ERB template dependency in SubmissionRenderer

This is out of scope for the current migration but could be done incrementally.

## Test Coverage

149 gem migration-related tests pass:
- `test/services/submission_builder_test.rb` (22 tests)
- `test/services/submission_renderer_test.rb` (17 tests)
- `test/services/validation_service_test.rb` (28 tests)
- `test/services/calculation_engine_test.rb` (48 tests)
- `test/models/xbrl/element_manifest_test.rb` (19 tests)
- `test/integration/amsf_gem_migration_test.rb` (13 tests)

---

*Migration completed by Claude Code - January 2026*
