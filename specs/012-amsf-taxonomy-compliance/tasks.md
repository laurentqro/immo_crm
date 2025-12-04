# Tasks: AMSF Taxonomy Compliance

**Input**: Design documents from `/specs/012-amsf-taxonomy-compliance/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Comprehensive test suite already exists at `test/compliance/` (57 tests, 4 failing). No new test tasks needed - implementation makes existing tests pass (TDD RED→GREEN phase).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- Rails monolith: `app/`, `config/`, `test/` at repository root
- Services: `app/services/`
- Configuration: `config/`
- Tests: `test/compliance/` (existing - no changes)

---

## Phase 1: Setup (Verification)

**Purpose**: Confirm current state and establish baseline

- [ ] T001 Run compliance tests to confirm 4 failures in `bin/rails test test/compliance/`
- [ ] T002 Review element mapping table in `docs/gap_analysis.md` for implementation reference

---

## Phase 2: Foundational (Shared Preparation)

**Purpose**: Prepare reference materials and understand dependencies

**⚠️ CRITICAL**: Complete before modifying any production code

- [ ] T003 Extract list of 9 valid elements (no change needed) from research.md for reference
- [ ] T004 Extract list of 14 invalid elements requiring changes from research.md for reference
- [ ] T005 Review XbrlTestHelper type registry in `test/support/xbrl_test_helper.rb` for type mapping

**Checkpoint**: Reference materials ready - user story implementation can begin

---

## Phase 3: User Story 1 - Valid Element Names in XBRL Output (Priority: P1) 🎯 MVP

**Goal**: Fix 21 invalid element names in CalculationEngine so generated XBRL passes taxonomy validation

**Independent Test**: `bin/rails test test/compliance/xbrl_taxonomy_test.rb` - all tests pass

### Implementation for User Story 1

- [ ] T006 [US1] Fix PEP client element `a1301` → `a12002B` in `client_statistics` method of `app/services/calculation_engine.rb`
- [ ] T007 [US1] Fix PEP beneficial owner element `a1502` → `a1502B` in `beneficial_owner_statistics` method of `app/services/calculation_engine.rb`
- [ ] T008 [US1] Fix purchase transaction count `a2102` → `a2102B` in `transaction_statistics` method of `app/services/calculation_engine.rb`
- [ ] T009 [US1] Fix sale transaction count `a2103` → `a2105B` in `transaction_statistics` method of `app/services/calculation_engine.rb`
- [ ] T010 [US1] Fix rental transaction count `a2104` → `a2107B` in `transaction_statistics` method of `app/services/calculation_engine.rb`
- [ ] T011 [US1] Fix purchase value `a2105` → `a2102BB` in `transaction_values` method of `app/services/calculation_engine.rb`
- [ ] T012 [US1] Fix sale value `a2106` → `a2105BB` in `transaction_values` method of `app/services/calculation_engine.rb`
- [ ] T013 [US1] Fix rental value `a2107` → `a2107BB` in `transaction_values` method of `app/services/calculation_engine.rb`
- [ ] T014 [US1] Fix cash transaction count `a2201` → `a2203` in `payment_method_statistics` method of `app/services/calculation_engine.rb`
- [ ] T015 [US1] Fix crypto transaction count `a2301` → `a2501A` in `payment_method_statistics` method of `app/services/calculation_engine.rb`
- [ ] T016 [US1] Remove crypto value `a2302` (combine into single `a2501A` element) in `payment_method_statistics` method of `app/services/calculation_engine.rb`
- [ ] T017 [US1] Remove PEP transaction method `pep_transaction_statistics` that generates invalid `a2401` in `app/services/calculation_engine.rb`
- [ ] T018 [US1] Remove `a2401` from `calculate_all` method's merge in `app/services/calculation_engine.rb`
- [ ] T019 [US1] Update `client_nationality_breakdown` to return nested hash `{"a1103" => {FR: count, GB: count}}` instead of `a1103_XX` in `app/services/calculation_engine.rb`
- [ ] T020 [US1] Run taxonomy tests to verify element name fixes in `bin/rails test test/compliance/xbrl_taxonomy_test.rb`

**Checkpoint**: Element names in CalculationEngine are valid - taxonomy tests should pass

---

## Phase 4: User Story 2 - Valid Element Mapping Configuration (Priority: P1)

**Goal**: Restructure YAML mapping to use only valid taxonomy element names as keys

**Independent Test**: `bin/rails test test/compliance/element_mapping_test.rb` - all tests pass

### Implementation for User Story 2

- [ ] T021 [P] [US2] Create backup of current mapping file `config/amsf_element_mapping.yml`
- [ ] T022 [US2] Remove `entity_identification` section (elements a0101-a0104 not in taxonomy) from `config/amsf_element_mapping.yml`
- [ ] T023 [US2] Remove `entity_info` section (elements a1001-a1003 not in taxonomy) from `config/amsf_element_mapping.yml`
- [ ] T024 [US2] Flatten `client_statistics` section - move element keys to top level, fixing invalid names per research.md in `config/amsf_element_mapping.yml`
- [ ] T025 [US2] Remove `client_nationalities` section (use dimensional contexts instead) from `config/amsf_element_mapping.yml`
- [ ] T026 [US2] Flatten `transaction_statistics` section with corrected element names in `config/amsf_element_mapping.yml`
- [ ] T027 [US2] Flatten `payment_statistics` section with corrected element names in `config/amsf_element_mapping.yml`
- [ ] T028 [US2] Flatten `str_statistics` section to top-level element key in `config/amsf_element_mapping.yml`
- [ ] T029 [US2] Rename `kyc_procedures` elements to `aCxxxx` prefix format in `config/amsf_element_mapping.yml`
- [ ] T030 [US2] Rename `compliance_policies` elements to `aCxxxx` prefix format in `config/amsf_element_mapping.yml`
- [ ] T031 [US2] Rename `training` elements to `aC13xx` format in `config/amsf_element_mapping.yml`
- [ ] T032 [US2] Rename `monitoring` elements to `aC18xx` format in `config/amsf_element_mapping.yml`
- [ ] T033 [US2] Run mapping validation tests in `bin/rails test test/compliance/element_mapping_test.rb`

**Checkpoint**: Element mapping configuration uses only valid taxonomy elements

---

## Phase 5: User Story 3 - Correct Element Types and Values (Priority: P2)

**Goal**: Ensure generated values match taxonomy-defined types with proper attributes

**Independent Test**: `bin/rails test test/compliance/xbrl_type_test.rb` - all tests pass

### Implementation for User Story 3

- [ ] T034 [US3] Update `format_value` method to use French booleans `Oui/Non` instead of `true/false` in `app/services/xbrl_generator.rb`
- [ ] T035 [US3] Verify integer elements include `unitRef="unit_pure"` attribute in `build_fact` method of `app/services/xbrl_generator.rb`
- [ ] T036 [US3] Verify monetary elements include `unitRef="unit_EUR"` and `decimals="2"` attributes in `build_fact` method of `app/services/xbrl_generator.rb`
- [ ] T037 [US3] Update `MONETARY_ELEMENTS` constant to include all monetary elements per data-model.md in `app/services/xbrl_generator.rb`
- [ ] T038 [US3] Run type compliance tests in `bin/rails test test/compliance/xbrl_type_test.rb`

**Checkpoint**: Element types and values conform to taxonomy specifications

---

## Phase 6: User Story 4 - Dimensional Contexts for Country Breakdowns (Priority: P2)

**Goal**: Replace underscore-suffixed country elements with proper XBRL dimensional contexts

**Independent Test**: `bin/rails test test/compliance/xbrl_dimension_test.rb` - all tests pass

**Depends on**: User Story 1 (country breakdown data format change)

### Implementation for User Story 4

- [ ] T039 [US4] Update `build_country_contexts` to create dimensional contexts from nested hash structure in `app/services/xbrl_generator.rb`
- [ ] T040 [US4] Update context generation to use `strix:CountryDimension` element inside segment in `app/services/xbrl_generator.rb`
- [ ] T041 [US4] Update `build_facts` to handle nested country hash and generate `a1103` facts with `contextRef` in `app/services/xbrl_generator.rb`
- [ ] T042 [US4] Ensure facts for country breakdown reference `ctx_country_{CODE}` contexts in `app/services/xbrl_generator.rb`
- [ ] T043 [US4] Run dimension compliance tests in `bin/rails test test/compliance/xbrl_dimension_test.rb`

**Checkpoint**: Country breakdowns use proper XBRL dimensional contexts

---

## Phase 7: User Story 5 - Complete XBRL Document Structure (Priority: P2)

**Goal**: Ensure generated XBRL documents have valid structure

**Independent Test**: `bin/rails test test/compliance/xbrl_structure_test.rb` - all tests pass

### Implementation for User Story 5

- [ ] T044 [US5] Verify all required namespaces (xbrl, link, xlink, iso4217, strix) are declared in `xbrl_attributes` method of `app/services/xbrl_generator.rb`
- [ ] T045 [US5] Verify every fact has valid `contextRef` pointing to existing context in `build_fact` method of `app/services/xbrl_generator.rb`
- [ ] T046 [US5] Verify numeric facts have valid `unitRef` pointing to existing unit in `build_fact` method of `app/services/xbrl_generator.rb`
- [ ] T047 [US5] Run structure compliance tests in `bin/rails test test/compliance/xbrl_structure_test.rb`

**Checkpoint**: XBRL document structure is valid and well-formed

---

## Phase 8: User Story 6 - Calculation Accuracy (Priority: P2)

**Goal**: Verify calculations produce correct values with valid element names

**Independent Test**: `bin/rails test test/compliance/xbrl_calculation_test.rb` - all tests pass

**Depends on**: User Story 1 (element names must be correct first)

### Implementation for User Story 6

- [ ] T048 [US6] Verify client statistics calculations produce correct counts with new element names in `app/services/calculation_engine.rb`
- [ ] T049 [US6] Verify transaction statistics calculations remain accurate after element name changes in `app/services/calculation_engine.rb`
- [ ] T050 [US6] Verify beneficial owner statistics calculations remain accurate after element name changes in `app/services/calculation_engine.rb`
- [ ] T051 [US6] Run calculation compliance tests in `bin/rails test test/compliance/xbrl_calculation_test.rb`

**Checkpoint**: Calculations are accurate with valid element names

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and cleanup

- [ ] T052 Run full compliance test suite in `bin/rails test test/compliance/`
- [ ] T053 Run RuboCop on modified files in `bin/rubocop app/services/calculation_engine.rb app/services/xbrl_generator.rb`
- [ ] T054 [P] Verify all 57 compliance tests pass with zero failures
- [ ] T055 [P] Update gap_analysis.md to reflect completed remediation in `docs/gap_analysis.md`
- [ ] T056 Run quickstart.md validation - generate sample XBRL and inspect output

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup - reference material preparation
- **User Story 1 (Phase 3)**: Depends on Foundational - can start after T005
- **User Story 2 (Phase 4)**: Depends on Foundational - can run in PARALLEL with US1 (different file)
- **User Story 3 (Phase 5)**: Depends on Foundational - can run in PARALLEL with US1/US2 (different focus)
- **User Story 4 (Phase 6)**: Depends on US1 completion (T019 country breakdown format change)
- **User Story 5 (Phase 7)**: Can run in PARALLEL with US3/US4 (different focus areas)
- **User Story 6 (Phase 8)**: Depends on US1 completion (element names must be correct)
- **Polish (Phase 9)**: Depends on all user stories complete

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 (P1) | Foundational | US2, US3, US5 |
| US2 (P1) | Foundational | US1, US3, US5 |
| US3 (P2) | Foundational | US1, US2, US5 |
| US4 (P2) | US1 (T019) | US5, US6 |
| US5 (P2) | Foundational | US1, US2, US3, US4 |
| US6 (P2) | US1 | US4, US5 |

### Within Each User Story

- Tasks within a story are sequential unless marked [P]
- Each story ends with a verification test run
- Story complete when its independent test passes

### Parallel Opportunities

**Maximum parallelism after Foundational phase:**

```
Developer A: US1 (CalculationEngine element fixes)
Developer B: US2 (YAML mapping restructure)
Developer C: US3 (Type handling) + US5 (Structure)
```

**After US1 completes:**

```
Developer A: US4 (Dimensional contexts)
Developer B: US6 (Calculation accuracy)
```

---

## Parallel Example: User Stories 1 and 2

```bash
# These can run simultaneously after Foundational phase:

# Developer A - User Story 1:
Task: "Fix PEP client element a1301 → a12002B in client_statistics method"
Task: "Fix purchase transaction count a2102 → a2102B in transaction_statistics method"
# ... continue with all T006-T020

# Developer B - User Story 2:
Task: "Remove entity_identification section from config/amsf_element_mapping.yml"
Task: "Flatten client_statistics section with corrected element names"
# ... continue with all T021-T033
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003-T005)
3. Complete Phase 3: User Story 1 (T006-T020) - **Fixes XBRL output**
4. Complete Phase 4: User Story 2 (T021-T033) - **Fixes configuration**
5. **STOP and VALIDATE**: Run `bin/rails test test/compliance/` - expect significant improvement
6. This delivers the core compliance fix

### Incremental Delivery

1. Setup + Foundational → Reference ready
2. US1 + US2 → Core element name fixes (MVP!)
3. US3 → Type handling (improves validation)
4. US4 → Dimensional contexts (enables country breakdowns)
5. US5 + US6 → Structure and calculation verification
6. Each phase adds compliance without breaking previous work

### Single Developer Strategy

Execute in priority order:
1. Setup + Foundational
2. US1 (most critical - fixes element names)
3. US2 (fixes configuration)
4. US3 (type handling)
5. US4 (dimensional contexts - needs US1)
6. US5 + US6 (verification)
7. Polish

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Tests already exist - implementation makes them pass (RED→GREEN)
- Verify each story's test file passes before moving to next
- Commit after each completed user story phase
- The YAML restructure (US2) is independent and can be done in parallel with code changes (US1)
