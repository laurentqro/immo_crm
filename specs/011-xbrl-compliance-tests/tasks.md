# Tasks: XBRL Compliance Test Suite

**Input**: Design documents from `/specs/011-xbrl-compliance-tests/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: This feature IS the test suite. All tasks create test infrastructure and test files.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Rails application**: `test/` for tests, `app/` for production code
- **Compliance tests**: `test/compliance/` directory
- **Test support**: `test/support/` directory

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create test directory structure and shared utilities

- [ ] T001 Create compliance test directory at test/compliance/
- [ ] T002 Create XbrlTestHelper module with XSD parsing in test/support/xbrl_test_helper.rb
- [ ] T003 [P] Add taxonomy_elements class method to parse all 323 non-abstract elements from docs/strix_Real_Estate_AML_CFT_survey_2025.xsd
- [ ] T004 [P] Add valid_element_names class method returning Set for O(1) lookup in test/support/xbrl_test_helper.rb
- [ ] T005 [P] Add element_types class method mapping element names to type symbols (:integer, :monetary, :string, :enum) in test/support/xbrl_test_helper.rb
- [ ] T006 [P] Add enum_values class method extracting allowed values for enum elements in test/support/xbrl_test_helper.rb
- [ ] T007 Add instance helper methods (parse_xbrl, extract_element_names, extract_element_value) in test/support/xbrl_test_helper.rb

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Base test class and fixtures that ALL compliance tests depend on

**⚠️ CRITICAL**: No user story tests can run until this phase is complete

- [ ] T008 Create XbrlComplianceTestCase base class in test/compliance/xbrl_compliance_test_case.rb
- [ ] T009 Add compliance_test_org fixture to test/fixtures/accounts.yml with RCI number 99MC12345
- [ ] T010 [P] Add calc_natural_1 through calc_natural_10 client fixtures (natural_person, not PEP) to test/fixtures/clients.yml
- [ ] T011 [P] Add calc_legal_1 through calc_legal_5 client fixtures (legal_entity) to test/fixtures/clients.yml
- [ ] T012 [P] Add calc_pep_1 and calc_pep_2 client fixtures (natural_person, is_pep: true) to test/fixtures/clients.yml
- [ ] T013 [P] Add calc_trust_1 client fixture (trust type) to test/fixtures/clients.yml
- [ ] T014 [P] Add calc_txn_1 (100K), calc_txn_2 (200K), calc_txn_3 (300K) transaction fixtures to test/fixtures/transactions.yml
- [ ] T015 [P] Add calc_txn_cash (50K, payment_method: cash) transaction fixture to test/fixtures/transactions.yml
- [ ] T016 Verify test fixtures load correctly by running bin/rails test test/compliance/xbrl_compliance_test_case.rb

**Checkpoint**: Foundation ready - user story test implementation can now begin in parallel

---

## Phase 3: User Story 1 - Taxonomy Compliance Validation (Priority: P1) 🎯 MVP

**Goal**: Validate that every generated XBRL element name exists in the official taxonomy schema

**Independent Test**: `bin/rails test test/compliance/xbrl_taxonomy_test.rb`

### Implementation for User Story 1

- [ ] T017 [US1] Create XbrlTaxonomyTest class in test/compliance/xbrl_taxonomy_test.rb
- [ ] T018 [US1] Add test "all generated elements exist in taxonomy" validating element names against XSD in test/compliance/xbrl_taxonomy_test.rb
- [ ] T019 [US1] Add test "no abstract elements appear in output" checking abstract="false" filter in test/compliance/xbrl_taxonomy_test.rb
- [ ] T020 [US1] Add test "element suffixes match taxonomy semantics" for B/W/BB/BW/R/TOLA patterns in test/compliance/xbrl_taxonomy_test.rb
- [ ] T021 [US1] Add descriptive error messages showing invalid element name and closest match suggestion in test/compliance/xbrl_taxonomy_test.rb
- [ ] T022 [US1] Verify all US1 tests pass with bin/rails test test/compliance/xbrl_taxonomy_test.rb

**Checkpoint**: User Story 1 complete - can validate element names independently

---

## Phase 4: User Story 2 - Complete Survey Coverage (Priority: P1)

**Goal**: Track taxonomy coverage and identify missing elements

**Independent Test**: `bin/rails test test/compliance/taxonomy_coverage_test.rb`

### Implementation for User Story 2

- [ ] T023 [US2] Create TaxonomyCoverageTest class in test/compliance/taxonomy_coverage_test.rb
- [ ] T024 [US2] Add test "reports total taxonomy element count" asserting 323 elements in test/compliance/taxonomy_coverage_test.rb
- [ ] T025 [US2] Add test "reports mapped element count" counting elements in config/amsf_element_mapping.yml in test/compliance/taxonomy_coverage_test.rb
- [ ] T026 [US2] Add test "calculates coverage percentage" computing mapped/total ratio in test/compliance/taxonomy_coverage_test.rb
- [ ] T027 [US2] Add test "lists unmapped elements by section" grouping Tab 1-4 coverage in test/compliance/taxonomy_coverage_test.rb
- [ ] T028 [US2] Add coverage report output helper method in test/compliance/taxonomy_coverage_test.rb
- [ ] T029 [US2] Verify all US2 tests pass with bin/rails test test/compliance/taxonomy_coverage_test.rb

**Checkpoint**: User Story 2 complete - can track coverage independently

---

## Phase 5: User Story 3 - Calculation Accuracy (Priority: P1)

**Goal**: Verify CalculationEngine produces correct aggregate values

**Independent Test**: `bin/rails test test/compliance/xbrl_calculation_test.rb`

### Implementation for User Story 3

- [ ] T030 [US3] Create XbrlCalculationTest class in test/compliance/xbrl_calculation_test.rb
- [ ] T031 [US3] Add test "client count a1101 equals total clients" using calc_* fixtures in test/compliance/xbrl_calculation_test.rb
- [ ] T032 [US3] Add test "natural person count a1102" using calc_natural_* fixtures in test/compliance/xbrl_calculation_test.rb
- [ ] T033 [US3] Add test "legal entity count a11502B" using calc_legal_* fixtures in test/compliance/xbrl_calculation_test.rb
- [ ] T034 [US3] Add test "PEP client count a1301" using calc_pep_* fixtures in test/compliance/xbrl_calculation_test.rb
- [ ] T035 [US3] Add test "transaction count a2101B" using calc_txn_* fixtures in test/compliance/xbrl_calculation_test.rb
- [ ] T036 [US3] Add test "transaction total a2104B equals 600000" summing calc_txn_1+2+3 in test/compliance/xbrl_calculation_test.rb
- [ ] T037 [US3] Add test "cash transaction count a2201" using calc_txn_cash fixture in test/compliance/xbrl_calculation_test.rb
- [ ] T038 [P] [US3] Add test "STR count a3101" with STR fixture in test/compliance/xbrl_calculation_test.rb
- [ ] T039 [US3] Verify all US3 tests pass with bin/rails test test/compliance/xbrl_calculation_test.rb

**Checkpoint**: User Story 3 complete - can verify calculations independently

---

## Phase 6: User Story 4 - XBRL Structure Validity (Priority: P2)

**Goal**: Validate XML structure, namespaces, contexts, and units

**Independent Test**: `bin/rails test test/compliance/xbrl_structure_test.rb`

### Implementation for User Story 4

- [ ] T040 [US4] Create XbrlStructureTest class in test/compliance/xbrl_structure_test.rb
- [ ] T041 [US4] Add test "generated XML is well-formed" parsing with Nokogiri in test/compliance/xbrl_structure_test.rb
- [ ] T042 [US4] Add test "root element is xbrl" in test/compliance/xbrl_structure_test.rb
- [ ] T043 [US4] Add test "includes required XBRL namespaces" checking xbrl, link, xlink, iso4217, strix in test/compliance/xbrl_structure_test.rb
- [ ] T044 [US4] Add test "schemaRef points to taxonomy" in test/compliance/xbrl_structure_test.rb
- [ ] T045 [US4] Add test "entity context exists with RCI identifier" in test/compliance/xbrl_structure_test.rb
- [ ] T046 [US4] Add test "period is instant with Dec 31 date" in test/compliance/xbrl_structure_test.rb
- [ ] T047 [US4] Add test "EUR unit exists for monetary facts" in test/compliance/xbrl_structure_test.rb
- [ ] T048 [US4] Add test "pure unit exists for count facts" in test/compliance/xbrl_structure_test.rb
- [ ] T049 [US4] Add test "all facts have valid contextRef" iterating facts in test/compliance/xbrl_structure_test.rb
- [ ] T050 [US4] Add test "monetary facts have unitRef to EUR" in test/compliance/xbrl_structure_test.rb
- [ ] T051 [US4] Verify all US4 tests pass with bin/rails test test/compliance/xbrl_structure_test.rb

**Checkpoint**: User Story 4 complete - can validate structure independently

---

## Phase 7: User Story 5 - Element Type Conformance (Priority: P2)

**Goal**: Validate element values match taxonomy-defined types

**Independent Test**: `bin/rails test test/compliance/xbrl_type_test.rb`

### Implementation for User Story 5

- [ ] T052 [US5] Create XbrlTypeTest class in test/compliance/xbrl_type_test.rb
- [ ] T053 [US5] Add test "integer elements have whole number values" checking no decimals in test/compliance/xbrl_type_test.rb
- [ ] T054 [US5] Add test "monetary elements have decimals attribute" in test/compliance/xbrl_type_test.rb
- [ ] T055 [US5] Add test "monetary elements reference EUR unit" in test/compliance/xbrl_type_test.rb
- [ ] T056 [US5] Add test "enum elements use Oui/Non values" not true/false in test/compliance/xbrl_type_test.rb
- [ ] T057 [US5] Add test "enum values match allowed enumeration" checking exact match in test/compliance/xbrl_type_test.rb
- [ ] T058 [US5] Add type validation helper methods in test/compliance/xbrl_type_test.rb
- [ ] T059 [US5] Verify all US5 tests pass with bin/rails test test/compliance/xbrl_type_test.rb

**Checkpoint**: User Story 5 complete - can validate types independently

---

## Phase 8: User Story 6 - Dimensional Context Handling (Priority: P2)

**Goal**: Validate country-specific dimensional contexts

**Independent Test**: `bin/rails test test/compliance/xbrl_dimension_test.rb`

### Implementation for User Story 6

- [ ] T060 [US6] Create XbrlDimensionTest class in test/compliance/xbrl_dimension_test.rb
- [ ] T061 [US6] Add multi-nationality client fixtures (FR, DE, MC) to test/fixtures/clients.yml
- [ ] T062 [US6] Add test "generates dimensional context per country" in test/compliance/xbrl_dimension_test.rb
- [ ] T063 [US6] Add test "country facts reference correct dimensional context" in test/compliance/xbrl_dimension_test.rb
- [ ] T064 [US6] Add test "CountryDimension element present in context" in test/compliance/xbrl_dimension_test.rb
- [ ] T065 [US6] Add test "country codes are valid ISO 3166-1 alpha-2" in test/compliance/xbrl_dimension_test.rb
- [ ] T066 [US6] Add test "clients without nationality excluded from breakdown" in test/compliance/xbrl_dimension_test.rb
- [ ] T067 [US6] Verify all US6 tests pass with bin/rails test test/compliance/xbrl_dimension_test.rb

**Checkpoint**: User Story 6 complete - can validate dimensions independently

---

## Phase 9: User Story 7 - Mapping Consistency (Priority: P3)

**Goal**: Validate YAML mapping configuration against taxonomy

**Independent Test**: `bin/rails test test/compliance/element_mapping_test.rb`

### Implementation for User Story 7

- [ ] T068 [US7] Create ElementMappingTest class in test/compliance/element_mapping_test.rb
- [ ] T069 [US7] Add test "all mapped elements exist in taxonomy" checking config/amsf_element_mapping.yml in test/compliance/element_mapping_test.rb
- [ ] T070 [US7] Add test "mapping types match taxonomy types" comparing type: in YAML to XSD type in test/compliance/element_mapping_test.rb
- [ ] T071 [US7] Add test "no obsolete elements in mapping" listing removed elements in test/compliance/element_mapping_test.rb
- [ ] T072 [US7] Add test "mapping sources are valid" checking from_settings, calculated sources in test/compliance/element_mapping_test.rb
- [ ] T073 [US7] Add warning output for mapping issues in test/compliance/element_mapping_test.rb
- [ ] T074 [US7] Verify all US7 tests pass with bin/rails test test/compliance/element_mapping_test.rb

**Checkpoint**: User Story 7 complete - can validate mapping independently

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final integration and documentation

- [ ] T075 Run full compliance test suite with bin/rails test test/compliance/
- [ ] T076 Verify test suite executes in under 30 seconds
- [ ] T077 [P] Add compliance tests to CI configuration in .github/workflows/ (if exists)
- [ ] T078 [P] Run RuboCop on all new test files with bin/rubocop test/compliance/ test/support/xbrl_test_helper.rb
- [ ] T079 Fix any RuboCop violations in test files
- [ ] T080 Run quickstart.md validation - verify documented commands work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user story tests
- **User Stories (Phase 3-9)**: All depend on Foundational phase completion
  - US1-US3 (P1) are highest priority - complete first
  - US4-US6 (P2) can proceed after P1 stories
  - US7 (P3) can proceed last
- **Polish (Phase 10)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on XbrlTestHelper.valid_element_names
- **User Story 2 (P1)**: Depends on XbrlTestHelper.taxonomy_elements
- **User Story 3 (P1)**: Depends on calc_* fixtures
- **User Story 4 (P2)**: Depends on XbrlTestHelper.parse_xbrl
- **User Story 5 (P2)**: Depends on XbrlTestHelper.element_types and enum_values
- **User Story 6 (P2)**: Depends on multi-nationality fixtures
- **User Story 7 (P3)**: Depends on XbrlTestHelper.valid_element_names

### Within Each User Story

- Create test class first
- Add test methods
- Add helper methods if needed
- Run tests to verify
- Story complete when all tests pass

### Parallel Opportunities

**Phase 1 Setup (after T002)**:
```text
T003, T004, T005, T006 can run in parallel (different methods in same file)
```

**Phase 2 Foundational (after T008, T009)**:
```text
T010, T011, T012, T013, T014, T015 can run in parallel (different fixtures)
```

**After Foundational Complete**:
```text
US1, US2, US3 can run in parallel (different test files)
Then US4, US5, US6 can run in parallel
Then US7
```

---

## Parallel Example: Setup Phase

```bash
# Launch XbrlTestHelper methods together:
Task: "Add taxonomy_elements class method in test/support/xbrl_test_helper.rb"
Task: "Add valid_element_names class method in test/support/xbrl_test_helper.rb"
Task: "Add element_types class method in test/support/xbrl_test_helper.rb"
Task: "Add enum_values class method in test/support/xbrl_test_helper.rb"
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: US1 - Taxonomy Validation
4. Complete Phase 4: US2 - Coverage Tracking
5. Complete Phase 5: US3 - Calculation Accuracy
6. **STOP and VALIDATE**: Run `bin/rails test test/compliance/`
7. The three P1 stories deliver the core value

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add US1 → Catch invalid element names (MVP!)
3. Add US2 → Track coverage gaps
4. Add US3 → Verify calculations
5. Add US4 → Validate structure
6. Add US5 → Validate types
7. Add US6 → Validate dimensions
8. Add US7 → Validate config

### Parallel Team Strategy

With 3 developers after Foundational:
- Developer A: US1 + US4 (taxonomy and structure)
- Developer B: US2 + US7 (coverage and mapping)
- Developer C: US3 + US5 + US6 (calculations and types)

---

## Notes

- [P] tasks = different files or independent methods
- [Story] label maps task to specific user story for traceability
- Each user story has its own test file that can run independently
- Verify tests FAIL before checking for implementation issues
- Commit after each story phase completion
- Stop at any checkpoint to validate story independently
- Run `bin/rails test test/compliance/` after each phase to catch regressions
