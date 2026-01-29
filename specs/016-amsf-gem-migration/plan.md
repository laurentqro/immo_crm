# Implementation Plan: AMSF Survey Gem Migration

**Branch**: `016-amsf-gem-migration` | **Date**: 2026-01-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-amsf-gem-migration/spec.md`

## Summary

Migrate from ad-hoc XBRL code (Taxonomy, TaxonomyElement, Survey classes) to the external `amsf_survey` and `amsf_survey-real_estate` gems. This replaces ~500 lines of taxonomy parsing, schema loading, and XBRL generation code with gem APIs while preserving CRM-specific calculation logic. The gem provides standardized questionnaire access, Ruby-native validation, and XBRL generation for AMSF regulatory submissions.

## Technical Context

**Language/Version**: Ruby 3.4.7 / Rails 8.1
**Primary Dependencies**: `amsf_survey`, `amsf_survey-real_estate`, Nokogiri, Turbo/Stimulus
**Storage**: PostgreSQL (existing schema - Submission, SubmissionValue models)
**Testing**: Minitest with fixtures, WebMock for HTTP stubs
**Target Platform**: Linux server (Docker/Kamal deployment)
**Project Type**: Web application (Rails monolith with Jumpstart Pro)
**Performance Goals**: Survey questionnaire loads < 2 seconds, validation < 5 seconds
**Constraints**: Zero data loss, XBRL output parity with current implementation
**Scale/Scope**: ~600 survey fields, ~500 lines of code to delete, ~200 lines to refactor

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check (Phase 0)

| Principle | Status | Notes |
|-----------|--------|-------|
| **TDD (Non-negotiable)** | PASS | Existing tests for SubmissionBuilder, SubmissionRenderer, ValidationService will be adapted. New gem integration tests required. |
| **YAGNI** | PASS | Migration removes complexity (taxonomy parsing) and replaces with simpler gem API calls. |
| **Single Responsibility** | PASS | Gem encapsulates taxonomy/generation; CRM keeps calculation logic. |
| **Rails Conventions First** | PASS | Using initializer for gem loading, standard service objects. |
| **Pundit Policies** | N/A | No authorization changes in this migration. |
| **Account Scoping** | PASS | SubmissionBuilder already scoped to organization. |
| **RuboCop Compliance** | PASS | All new code will pass RuboCop. |

**Gate Status**: PASSED - No violations requiring justification.

### Post-Design Check (Phase 1)

| Principle | Status | Notes |
|-----------|--------|-------|
| **TDD (Non-negotiable)** | PASS | Comparison test strategy defined in research.md. Tests will verify XBRL parity before deletion. |
| **YAGNI** | PASS | Design keeps dual submission pattern simple. No unnecessary abstractions. |
| **Single Responsibility** | PASS | Clear separation: gem handles taxonomy/XBRL, CRM handles persistence/calculations. |
| **Rails Conventions First** | PASS | Service object pattern maintained. Standard initializer for gem loading. |
| **Pundit Policies** | N/A | No new authorization required. |
| **Account Scoping** | PASS | Data flow preserves organization scoping throughout. |
| **RuboCop Compliance** | PASS | Contracts specify clean interfaces. |

**Post-Design Gate Status**: PASSED - Design aligns with constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/016-amsf-gem-migration/
├── plan.md              # This file
├── research.md          # Phase 0 output - gem API research
├── data-model.md        # Phase 1 output - entity mappings
├── quickstart.md        # Phase 1 output - gem integration guide
├── contracts/           # Phase 1 output - API contracts
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Files to DELETE (gem provides these)
app/models/xbrl/taxonomy.rb           # ~250 lines - taxonomy parsing
app/models/xbrl/taxonomy_element.rb   # ~50 lines - element value object
app/models/xbrl/survey.rb             # ~100 lines - section definitions
docs/taxonomy/                        # Taxonomy XML files
config/xbrl_short_labels.yml          # Short label mappings
config/initializers/xbrl_taxonomy.rb  # Boot-time loading

# Files to REFACTOR
app/models/xbrl/element_manifest.rb   # Adapt to use gem questionnaire
app/services/submission_builder.rb    # Use gem build/validate APIs
app/services/submission_renderer.rb   # Use gem to_xbrl for XBRL output
app/services/calculation_engine.rb    # Map to gem semantic field names
app/services/validation_service.rb    # Optional external Arelle support
app/views/submissions/show.xml.erb    # DELETE - gem generates XBRL

# Files to CREATE
config/initializers/amsf_survey.rb    # Gem initialization and verification

# Test files to UPDATE
test/services/submission_builder_test.rb
test/services/submission_renderer_test.rb
test/services/calculation_engine_test.rb
test/models/xbrl/element_manifest_test.rb

# Test files to CREATE
test/integration/amsf_gem_migration_test.rb  # XBRL output comparison
```

**Structure Decision**: Existing Rails monolith structure maintained. Migration replaces files in `app/models/xbrl/` and `app/services/` directories while preserving test structure in `test/`.

## Complexity Tracking

> No constitution violations - this section intentionally left minimal.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
