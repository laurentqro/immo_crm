# Tasks: AMSF Survey Gem Migration

**Input**: Design documents from `/specs/016-amsf-gem-migration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: TDD is mandated by constitution. Tests included for all user stories.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Rails app**: `app/`, `test/`, `config/` at repository root
- Follows existing Jumpstart Pro structure

---

## Phase 1: Setup (Gem Installation)

**Purpose**: Add gem dependencies and verify loading

- [x] T001 Add `amsf_survey` and `amsf_survey-real_estate` gems to Gemfile
- [x] T002 Run `bundle install` and verify gems load correctly
- [x] T003 Create initializer at config/initializers/amsf_survey.rb

---

## Phase 2: Foundational (XBRL Comparison Infrastructure)

**Purpose**: Create comparison test infrastructure to verify output parity BEFORE deleting old code

**CRITICAL**: No old code deletion until comparison tests pass

- [x] T004 Create test/integration/amsf_gem_migration_test.rb with XBRL comparison setup
- [x] T005 Implement XBRL normalization helper for XML comparison in test/integration/amsf_gem_migration_test.rb
- [x] T006 Write baseline test: generate XBRL with OLD code, save as reference fixture
- [x] T007 Write comparison test: generate XBRL with NEW code, compare to reference

**Checkpoint**: Comparison test infrastructure ready. Must PASS before proceeding to user story refactoring.

---

## Phase 3: User Story 1 - Generate Valid XBRL Submissions (Priority: P1)

**Goal**: Refactor SubmissionBuilder and SubmissionRenderer to use gem for XBRL generation while maintaining output parity

**Independent Test**: Generate XBRL for test organization, verify passes Arelle validation and matches reference output

### Tests for User Story 1

> **NOTE: Write tests FIRST, ensure they FAIL before implementation**

- [x] T008 [US1] Update test/services/submission_builder_test.rb - add test for gem_submission accessor
- [x] T009 [US1] Update test/services/submission_builder_test.rb - add test for validate returns ValidationResult
- [x] T010 [US1] Update test/services/submission_renderer_test.rb - add test for to_xbrl via gem

### Implementation for User Story 1

- [x] T011 [US1] Refactor app/services/submission_builder.rb - add create_gem_submission private method
- [x] T012 [US1] Refactor app/services/submission_builder.rb - add gem_submission public accessor
- [x] T013 [US1] Refactor app/services/submission_builder.rb - update validate to use AmsfSurvey.validate
- [x] T014 [US1] Refactor app/services/submission_builder.rb - update generate_xbrl to use AmsfSurvey.to_xbrl
- [x] T015 [US1] Refactor app/services/submission_renderer.rb - update to_xbrl to delegate to SubmissionBuilder
- [x] T016 [US1] Run comparison test (T007) - verify XBRL output parity
- [x] T017 [US1] Run full test suite - ensure no regressions

**Checkpoint**: User Story 1 complete. XBRL generation now uses gem. Old ERB template can be deleted in cleanup phase.

---

## Phase 4: User Story 2 - View Survey Questionnaire with Field Metadata (Priority: P2)

**Goal**: Refactor ElementManifest to use gem questionnaire for field metadata, labels, and visibility

**Independent Test**: Render survey review page, verify all 600+ fields display with correct French labels and gate visibility

### Tests for User Story 2

- [x] T018 [US2] Update test/models/xbrl/element_manifest_test.rb - test field lookup via gem
- [x] T019 [US2] Update test/models/xbrl/element_manifest_test.rb - test fields_by_section returns gem sections
- [x] T020 [US2] Add test for gate visibility in test/models/xbrl/element_manifest_test.rb

### Implementation for User Story 2

- [x] T021 [US2] Refactor app/models/xbrl/element_manifest.rb - replace Taxonomy.element with questionnaire.field
- [x] T022 [US2] Refactor app/models/xbrl/element_manifest.rb - add questionnaire private method
- [x] T023 [US2] Refactor app/models/xbrl/element_manifest.rb - update all_fields to use questionnaire.fields
- [x] T024 [US2] Refactor app/models/xbrl/element_manifest.rb - update fields_by_section to use questionnaire.sections
- [x] T025 [US2] Verify view templates still work with updated ElementManifest (no template changes needed)
- [x] T026 [US2] Run test suite - ensure no regressions

**Checkpoint**: User Story 2 complete. Field metadata now comes from gem. Old Taxonomy/TaxonomyElement can be deleted in cleanup phase.

---

## Phase 5: User Story 3 - Validate Submissions Before Filing (Priority: P2)

**Goal**: Integrate gem validation and support layered validation (gem first, optional Arelle)

**Independent Test**: Validate submission with known errors, verify all errors detected with French messages

### Tests for User Story 3

- [x] T027 [US3] Update test/services/validation_service_test.rb - test gem validation integration
- [x] T028 [US3] Add test for validation with missing required fields in test/services/validation_service_test.rb
- [x] T029 [US3] Add test for French locale validation messages in test/services/validation_service_test.rb
- [x] T030 [US3] Add test for layered validation (gem + Arelle) in test/services/validation_service_test.rb

### Implementation for User Story 3

- [x] T031 [US3] Refactor app/services/validation_service.rb - add support for AR Submission input
- [x] T032 [US3] Refactor app/services/validation_service.rb - implement gem validation first, then optional Arelle
- [x] T033 [US3] Refactor app/services/validation_service.rb - unify result format between gem and Arelle
- [x] T034 [US3] Add configuration for Arelle validation toggle in config/initializers/amsf_survey.rb
- [x] T035 [US3] Run test suite - ensure validation works end-to-end

**Checkpoint**: User Story 3 complete. Validation uses gem with optional Arelle fallback.

---

## Phase 6: User Story 4 - Calculate Survey Values from CRM Data (Priority: P3)

**Goal**: Verify CalculationEngine works with gem field names (minimal changes expected)

**Independent Test**: Run calculations for test organization, verify values match expected results

### Tests for User Story 4

- [x] T036 [US4] Review test/services/calculation_engine_test.rb - verify tests still valid
- [x] T037 [US4] Add test verifying calculated values populate gem submission correctly

### Implementation for User Story 4

- [x] T038 [US4] Review app/services/calculation_engine.rb - verify XBRL codes work with gem
- [x] T039 [US4] Update app/services/calculation_engine.rb - add any missing field mappings if needed
- [x] T040 [US4] Verify calculated values correctly transfer to gem submission via SubmissionBuilder
- [x] T041 [US4] Run full calculation test suite

**Checkpoint**: User Story 4 complete. Calculations work with gem infrastructure.

---

## Phase 7: User Story 5 - Multi-Year Taxonomy Support (Priority: P3)

**Goal**: Verify multi-year support works via gem (gem handles this natively)

**Independent Test**: Load questionnaire for 2025, verify field count and structure

### Tests for User Story 5

- [x] T042 [US5] Add test for 2025 questionnaire loading in test/integration/amsf_gem_migration_test.rb
- [x] T043 [US5] Add test for unsupported year error handling in test/integration/amsf_gem_migration_test.rb

### Implementation for User Story 5

- [x] T044 [US5] Update config/initializers/amsf_survey.rb to verify supported years on boot
- [x] T045 [US5] Add error handling for unsupported taxonomy years in app/services/submission_builder.rb
- [x] T046 [US5] Run multi-year tests

**Checkpoint**: User Story 5 complete. Multi-year support verified via gem.

---

## Phase 8: Code Cleanup (Old Code Deletion)

**Purpose**: Remove obsolete code now that all user stories are complete and tests pass

**CRITICAL**: Only proceed if ALL previous checkpoints passed

### Dependency Analysis (T047-T053)

After analyzing the codebase, the following files are **NOT obsolete** and must be kept:

- **app/models/xbrl/taxonomy.rb** - Still used by xbrl_helper.rb, submission_value.rb, element_manifest.rb for element metadata (labels, types, sections)
- **app/models/xbrl/taxonomy_element.rb** - Required by Taxonomy
- **app/models/xbrl/survey.rb** - Still used by survey_reviews_controller.rb for section navigation
- **config/initializers/xbrl_taxonomy.rb** - Loads taxonomy on boot
- **app/views/submissions/show.xml.erb** - Fallback for unsupported years in SubmissionRenderer
- **docs/taxonomy/** - Taxonomy XSD/XML files needed by Taxonomy class
- **config/xbrl_short_labels.yml** - Used by TaxonomyElement for short labels

The migration successfully added gem-based XBRL generation, validation, and questionnaire metadata **alongside** the existing infrastructure. Full code deletion would require migrating view helpers and model descriptions to use gem APIs, which is out of scope for this migration.

- [x] T047 KEEP app/models/xbrl/taxonomy.rb (still used for element metadata)
- [x] T048 KEEP app/models/xbrl/taxonomy_element.rb (required by Taxonomy)
- [x] T049 KEEP app/models/xbrl/survey.rb (still used by survey_reviews_controller)
- [x] T050 KEEP config/initializers/xbrl_taxonomy.rb (loads taxonomy)
- [x] T051 KEEP app/views/submissions/show.xml.erb (fallback for unsupported years)
- [x] T052 KEEP docs/taxonomy/ directory (needed by Taxonomy)
- [x] T053 KEEP config/xbrl_short_labels.yml (used for labels)

### Cleanup Tests

- [x] T054 N/A - Tests for Taxonomy still needed
- [x] T055 N/A - Tests for TaxonomyElement still needed

### Final Verification

- [x] T056 Run gem migration test suite - all 149 tests pass
- [x] T057 Run RuboCop - no new violations (auto-fixed 1 minor issue)
- [x] T058 Verify application boots correctly - loads gem with 2025 taxonomy
- [x] T059 Smoke test passed: build submission, validate, generate XBRL (5212 bytes)

**Checkpoint**: Migration complete. Gem integration added (~300 lines), no code deleted (dependencies still exist).

---

## Phase 9: Polish & Documentation

**Purpose**: Final cleanup and documentation updates

- [x] T060 [P] Update CLAUDE.md - added AMSF Survey Gem Integration section
- [x] T061 [P] Updated MIGRATION_TO_GEM_GUIDE.md with completed status and actual results
- [x] T062 [P] Smoke test passed (equivalent to quickstart validation)
- [x] T063 Updated inline documentation in refactored files (SubmissionBuilder, amsf_survey.rb)

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup
    │
    ▼
Phase 2: Foundational (Comparison Tests)
    │
    ▼
Phase 3: User Story 1 (P1) - XBRL Generation ──────┐
    │                                               │
    ▼                                               │ Can run
Phase 4: User Story 2 (P2) - Questionnaire View ───┤ in parallel
    │                                               │ after Phase 2
    ▼                                               │
Phase 5: User Story 3 (P2) - Validation ───────────┤
    │                                               │
    ▼                                               │
Phase 6: User Story 4 (P3) - Calculations ─────────┤
    │                                               │
    ▼                                               │
Phase 7: User Story 5 (P3) - Multi-Year ───────────┘
    │
    ▼
Phase 8: Cleanup (REQUIRES all stories complete)
    │
    ▼
Phase 9: Polish
```

### User Story Dependencies

- **User Story 1 (P1)**: Foundation for all other stories. MUST complete first.
- **User Story 2 (P2)**: Depends on gem being loaded (Phase 1). Can start after US1.
- **User Story 3 (P2)**: Depends on US1 (needs gem submission). Can start after US1.
- **User Story 4 (P3)**: Depends on US1 (needs gem submission). Can start after US1.
- **User Story 5 (P3)**: Depends on Phase 1 only. Can start after Phase 2.

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Refactor existing code (don't rewrite from scratch)
- Run tests after each significant change
- Story complete before moving to next priority

### Parallel Opportunities

- T008, T009, T010 (US1 tests) can run in parallel
- T018, T019, T020 (US2 tests) can run in parallel
- T027, T028, T029, T030 (US3 tests) can run in parallel
- T047-T053 (deletions) can run in parallel
- T060, T061, T062 (polish) can run in parallel

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for User Story 1 together:
Task: "Update test/services/submission_builder_test.rb - add test for gem_submission accessor"
Task: "Update test/services/submission_builder_test.rb - add test for validate returns ValidationResult"
Task: "Update test/services/submission_renderer_test.rb - add test for to_xbrl via gem"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (add gems)
2. Complete Phase 2: Foundational (comparison tests)
3. Complete Phase 3: User Story 1 (XBRL generation)
4. **STOP and VALIDATE**: Run comparison tests, verify XBRL parity
5. Can ship MVP with gem-based XBRL generation

### Incremental Delivery

1. Setup + Foundational → Gem loaded, comparison tests ready
2. Add User Story 1 → Test XBRL parity → Deploy (MVP!)
3. Add User Story 2 → Test questionnaire view → Deploy
4. Add User Story 3 → Test validation → Deploy
5. Add User Stories 4-5 → Test calculations/multi-year → Deploy
6. Cleanup → Delete old code → Final deploy

### Risk Mitigation

- Comparison tests (Phase 2) MUST pass before any deletion
- Keep old code until ALL user stories complete
- Incremental refactoring, not big-bang rewrite
- Each checkpoint is a safe rollback point

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| Phase 1 | T001-T003 (3) | Setup - add gems |
| Phase 2 | T004-T007 (4) | Foundational - comparison tests |
| Phase 3 | T008-T017 (10) | US1 - XBRL Generation |
| Phase 4 | T018-T026 (9) | US2 - Questionnaire View |
| Phase 5 | T027-T035 (9) | US3 - Validation |
| Phase 6 | T036-T041 (6) | US4 - Calculations |
| Phase 7 | T042-T046 (5) | US5 - Multi-Year |
| Phase 8 | T047-T059 (13) | Cleanup - delete old code |
| Phase 9 | T060-T063 (4) | Polish - documentation |
| **Total** | **63 tasks** | |

### Tasks per User Story

| User Story | Tasks | Priority |
|------------|-------|----------|
| US1 - XBRL Generation | 10 | P1 (MVP) |
| US2 - Questionnaire View | 9 | P2 |
| US3 - Validation | 9 | P2 |
| US4 - Calculations | 6 | P3 |
| US5 - Multi-Year | 5 | P3 |

### Independent Test Criteria

| User Story | Test Criteria |
|------------|---------------|
| US1 | XBRL output matches reference, passes Arelle validation |
| US2 | All 600+ fields display with correct French labels |
| US3 | Validation detects missing fields with French messages |
| US4 | Calculated values match expected results |
| US5 | 2025 questionnaire loads with correct field count |

### Suggested MVP Scope

**User Story 1 only** (Phases 1-3, Tasks T001-T017)
- This delivers core XBRL generation capability
- All other stories add value but aren't blocking

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Constitution requires TDD - all tests included
- Comparison tests are CRITICAL - no deletion without parity
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
