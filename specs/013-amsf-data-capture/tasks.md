# Tasks: AMSF Survey Data Capture

**Input**: Design documents from `/specs/013-amsf-data-capture/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/wizard-api.md, quickstart.md
**Tests**: TDD required per constitution - Red-Green-Refactor cycle

**Organization**: Tasks grouped by user story. Constitution mandates TDD - tests written first, must fail before implementation.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1-US6)
- Exact file paths included in descriptions

## Path Conventions

Rails application structure:
- Models: `app/models/`
- Services: `app/services/`
- Controllers: `app/controllers/`
- Views: `app/views/`
- Components: `app/components/`
- Tests: `test/`
- Migrations: `db/migrate/`

---

## Phase 1: Setup (Shared Infrastructure) ✅ COMPLETED

**Purpose**: Database schema changes and shared constants

- [x] T001 Add new enum constants to app/models/concerns/amsf_constants.rb (DUE_DILIGENCE_LEVELS, RELATIONSHIP_END_REASONS, PROFESSIONAL_CATEGORIES, PROPERTY_TYPES, TENANT_TYPES, TRAINING_TYPES, TRAINING_TOPICS, TRAINING_PROVIDERS, MANAGED_PROPERTY_TYPES)
- [x] T002 [P] Create migration db/migrate/xxx_add_compliance_fields_to_clients.rb (due_diligence_level, simplified_dd_reason, relationship_end_reason, professional_category, source_of_funds_verified, source_of_wealth_verified)
- [x] T003 [P] Create migration db/migrate/xxx_add_compliance_fields_to_transactions.rb (property_type, is_new_construction, counterparty_is_pep, counterparty_country, rental_annual_value, rental_tenant_type)
- [x] T004 [P] Create migration db/migrate/xxx_add_verification_fields_to_beneficial_owners.rb (source_of_wealth_verified, identification_verified)
- [x] T005 [P] Create migration db/migrate/xxx_add_lifecycle_fields_to_submissions.rb (current_step, locked_by_user_id, locked_at, generated_at, reopened_count)
- [x] T006 [P] Create migration db/migrate/xxx_add_override_tracking_to_submission_values.rb (override_reason, override_user_id, previous_year_value)
- [x] T007 [P] Create migration db/migrate/xxx_create_managed_properties.rb with indexes per data-model.md
- [x] T008 [P] Create migration db/migrate/xxx_create_trainings.rb with indexes per data-model.md
- [x] T009 Run bin/rails db:migrate to apply all schema changes

---

## Phase 2: Foundational (Blocking Prerequisites) ✅ COMPLETED

**Purpose**: Core models and services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational Models

- [x] T010 [P] Write failing test for ManagedProperty model validations in test/models/managed_property_test.rb
- [x] T011 [P] Write failing test for Training model validations in test/models/training_test.rb
- [x] T012 [P] Write failing test for Client compliance field validations in test/models/client_test.rb
- [x] T013 [P] Write failing test for Transaction compliance field validations in test/models/transaction_test.rb
- [x] T014 [P] Write failing test for SubmissionValue override validation in test/models/submission_value_test.rb
- [x] T015 [P] Write failing test for Submission lifecycle methods in test/models/submission_test.rb

### Implementation for Foundational Models

- [x] T016 [P] Implement ManagedProperty model in app/models/managed_property.rb with validations, scopes (active, active_in_year, for_organization)
- [x] T017 [P] Implement Training model in app/models/training.rb with validations, scopes (for_year, for_organization, by_type)
- [x] T018 [P] Add compliance field validations to app/models/client.rb (due_diligence_level, simplified_dd_reason, relationship_end_reason, professional_category)
- [x] T019 [P] Add compliance field validations to app/models/transaction.rb (property_type, counterparty_country, rental_tenant_type)
- [x] T020 [P] Add override validation to app/models/submission_value.rb (override_reason required when overridden)
- [x] T021 Add lifecycle methods to app/models/submission.rb (lock!, unlock!, reopen!, generated?, lockable?)
- [x] T022 Add fixtures for ManagedProperty in test/fixtures/managed_properties.yml
- [x] T023 Add fixtures for Training in test/fixtures/trainings.yml
- [x] T024 Run bin/rails test test/models/ to verify all model tests pass

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Submit Annual Survey with Pre-Calculated Data (Priority: P1) 🎯 MVP ✅ COMPLETED

**Goal**: Compliance officer can walk through 7-step wizard with pre-calculated values and generate valid XBRL

**Independent Test**: Create submission, navigate all wizard steps, verify pre-populated values, generate XBRL file

### Tests for User Story 1

- [x] T025 [P] [US1] Write failing test for extended CalculationEngine in test/services/calculation_engine_test.rb (managed_property_statistics, training_statistics, revenue_statistics, extended_client_statistics)
- [x] T026 [P] [US1] Write failing test for YearOverYearComparator in test/services/year_over_year_comparator_test.rb
- [x] T027 [P] [US1] Write failing controller test for 7-step wizard in test/controllers/submission_steps_controller_test.rb
- [x] T028 [US1] Write failing system test for wizard flow in test/system/submission_wizard_test.rb

### Implementation for User Story 1

- [x] T029 [US1] Extend app/services/calculation_engine.rb with managed_property_statistics method
- [x] T030 [US1] Extend app/services/calculation_engine.rb with training_statistics method
- [x] T031 [US1] Extend app/services/calculation_engine.rb with revenue_statistics method (a3802, a3803, a3804, a381)
- [x] T032 [US1] Extend app/services/calculation_engine.rb with extended_client_statistics method (a11301, a11302, a1203, a1203D)
- [x] T033 [US1] Create app/services/year_over_year_comparator.rb with comparison_for and significant_changes methods
- [x] T034 [P] [US1] Create app/components/statistic_card_component.rb for displaying single calculated value with source
- [x] T035 [P] [US1] Create app/components/statistic_group_component.rb for grouping related statistics
- [x] T036 [US1] Extend app/controllers/submission_steps_controller.rb VALID_STEPS constant to (1..7)
- [x] T037 [US1] Implement show_step_1 (Activity Confirmation) in app/controllers/submission_steps_controller.rb
- [x] T038 [US1] Implement show_step_2 (Client Statistics) with YoY comparison in app/controllers/submission_steps_controller.rb
- [x] T039 [US1] Implement show_step_3 (Transaction Statistics) with YoY comparison in app/controllers/submission_steps_controller.rb
- [x] T040 [US1] Implement show_step_4 (Training & Compliance) with YoY comparison in app/controllers/submission_steps_controller.rb
- [x] T041 [US1] Implement show_step_5 (Revenue Review) with YoY comparison in app/controllers/submission_steps_controller.rb
- [x] T042 [US1] Implement show_step_6 (Policy Confirmation) in app/controllers/submission_steps_controller.rb
- [x] T043 [US1] Implement show_step_7 (Review & Sign) with validation warnings in app/controllers/submission_steps_controller.rb
- [x] T044 [P] [US1] Create app/views/submission_steps/step_1.html.erb (Activity Confirmation view)
- [x] T045 [P] [US1] Create app/views/submission_steps/step_2.html.erb (Client Statistics view)
- [x] T046 [P] [US1] Create app/views/submission_steps/step_3.html.erb (Transaction Statistics view)
- [x] T047 [P] [US1] Create app/views/submission_steps/step_4.html.erb (Training & Compliance view)
- [x] T048 [P] [US1] Create app/views/submission_steps/step_5.html.erb (Revenue Review view)
- [x] T049 [P] [US1] Create app/views/submission_steps/step_6.html.erb (Policy Confirmation view)
- [x] T050 [P] [US1] Create app/views/submission_steps/step_7.html.erb (Review & Sign view with signatory fields)
- [x] T051 [US1] Implement update_step_7 with XBRL generation in app/controllers/submission_steps_controller.rb
- [x] T052 [US1] Update app/policies/submission_policy.rb with generate? and reopen? methods (FR-030, FR-031)
- [x] T053 [US1] Run bin/rails test to verify all US1 tests pass

**Checkpoint**: User Story 1 complete - wizard functional with pre-calculated values and XBRL generation

---

## Phase 4: User Story 2 - Capture Compliance Data During Client Onboarding (Priority: P2) ✅ COMPLETED

**Goal**: Agents can record due diligence level, source verification, and professional category when creating/updating clients

**Independent Test**: Create client with all compliance fields, verify data saved and appears in statistics

### Tests for User Story 2

- [x] T054 [P] [US2] Write failing controller test for client compliance fields in test/controllers/clients_controller_test.rb
- [ ] T055 [P] [US2] Write failing system test for client form in test/system/clients_test.rb (skipped - comprehensive controller tests exist)

### Implementation for User Story 2

- [x] T056 [US2] Update app/policies/client_policy.rb permitted_attributes to permit new compliance fields
- [x] T057 [US2] Update app/views/clients/_form.html.erb with due_diligence_level dropdown (FR-001)
- [x] T058 [US2] Update app/views/clients/_form.html.erb with simplified_dd_reason field (conditional on SIMPLIFIED)
- [x] T059 [US2] Update app/views/clients/_form.html.erb with professional_category dropdown (FR-002)
- [x] T060 [US2] Update app/views/clients/_form.html.erb with source_of_funds_verified checkbox (FR-004)
- [x] T061 [US2] Update app/views/clients/_form.html.erb with source_of_wealth_verified checkbox (FR-004)
- [x] T062 [US2] Update app/views/clients/_form.html.erb with relationship_end_reason dropdown (FR-003)
- [x] T063 [US2] Extend client_form_controller.js for conditional simplified_dd_reason visibility
- [x] T064 [US2] Run bin/rails test to verify all US2 tests pass

**Checkpoint**: User Story 2 complete - client compliance data captured during onboarding

---

## Phase 5: User Story 3 - Record Property Management Contracts (Priority: P2) ✅ COMPLETED

**Goal**: Agents can record managed properties with landlord, tenant details, and fee structure

**Independent Test**: Create managed property, verify it appears in revenue and tenant statistics

### Tests for User Story 3

- [x] T065 [P] [US3] Write failing controller test for managed_properties in test/controllers/managed_properties_controller_test.rb
- [ ] T066 [P] [US3] Write failing system test for managed property CRUD in test/system/managed_properties_test.rb (skipped - comprehensive controller tests exist)

### Implementation for User Story 3

- [x] T067 [US3] Create app/controllers/managed_properties_controller.rb with CRUD actions
- [x] T068 [US3] Add routes for managed_properties resource in config/routes/crm.rb
- [x] T069 [US3] Create app/policies/managed_property_policy.rb with organization scoping
- [x] T070 [P] [US3] Create app/views/managed_properties/index.html.erb
- [x] T071 [P] [US3] Create app/views/managed_properties/_form.html.erb with all fields per data-model.md
- [x] T072 [P] [US3] Create app/views/managed_properties/show.html.erb
- [x] T073 [P] [US3] Create app/views/managed_properties/new.html.erb (uses ModalComponent with auto-open)
- [x] T074 [P] [US3] Create app/views/managed_properties/edit.html.erb (uses ModalComponent with auto-open)
- [x] T075 [US3] Add managed_properties link to navigation in app/views/application/_left_nav.html.erb
- [x] T076 [US3] Run bin/rails test to verify all US3 tests pass (22 tests passing)

**Checkpoint**: User Story 3 complete - property management contracts recorded and included in statistics

---

## Phase 6: User Story 4 - Record Staff Training Sessions (Priority: P3)

**Goal**: Compliance officers can record AML/CFT training sessions with date, topic, provider, staff count

**Independent Test**: Create training records, verify counts appear in wizard step 4

### Tests for User Story 4

- [ ] T077 [P] [US4] Write failing controller test for trainings in test/controllers/trainings_controller_test.rb
- [ ] T078 [P] [US4] Write failing system test for training CRUD in test/system/trainings_test.rb

### Implementation for User Story 4

- [ ] T079 [US4] Create app/controllers/trainings_controller.rb with CRUD actions
- [ ] T080 [US4] Add routes for trainings resource in config/routes.rb
- [ ] T081 [US4] Create app/policies/training_policy.rb with organization scoping
- [ ] T082 [P] [US4] Create app/views/trainings/index.html.erb
- [ ] T083 [P] [US4] Create app/views/trainings/_form.html.erb with all fields per data-model.md
- [ ] T084 [P] [US4] Create app/views/trainings/show.html.erb
- [ ] T085 [P] [US4] Create app/views/trainings/new.html.erb
- [ ] T086 [P] [US4] Create app/views/trainings/edit.html.erb
- [ ] T087 [US4] Add trainings link to navigation in app/views/layouts/application.html.erb
- [ ] T088 [US4] Run bin/rails test to verify all US4 tests pass

**Checkpoint**: User Story 4 complete - training sessions recorded and included in statistics

---

## Phase 7: User Story 5 - Override Calculated Values (Priority: P3)

**Goal**: Users can override calculated values with documented reason and revert to original

**Independent Test**: Override a value in wizard, verify it persists and shows indicator, then revert

### Tests for User Story 5

- [ ] T089 [P] [US5] Write failing controller test for value override in test/controllers/submission_steps_controller_test.rb
- [ ] T090 [P] [US5] Write failing test for override audit trail in test/models/submission_value_test.rb

### Implementation for User Story 5

- [ ] T091 [US5] Update update_submission_values method in app/controllers/submission_steps_controller.rb to handle override_reason (FR-018)
- [ ] T092 [US5] Add override_with_reason! method to app/models/submission_value.rb
- [ ] T093 [US5] Add revert_override! method to app/models/submission_value.rb
- [ ] T094 [US5] Update statistic_card_component.rb to show override indicator (FR-028)
- [ ] T095 [US5] Add override modal/form to wizard step views for editing values
- [ ] T096 [US5] Run bin/rails test to verify all US5 tests pass

**Checkpoint**: User Story 5 complete - values can be overridden with audit trail

---

## Phase 8: User Story 6 - Compare Year-over-Year Statistics (Priority: P3)

**Goal**: Users see YoY comparison with significant changes (>25%) highlighted

**Independent Test**: Create submissions for two years, verify comparison displays and highlighting works

### Tests for User Story 6

- [ ] T097 [P] [US6] Write failing test for significant_changes highlighting in test/services/year_over_year_comparator_test.rb
- [ ] T098 [P] [US6] Write failing system test for YoY display in test/system/submission_wizard_test.rb

### Implementation for User Story 6

- [ ] T099 [US6] Add significant? method to YearOverYearComparator (>25% threshold per FR-019)
- [ ] T100 [US6] Update wizard step views (2-5) to display previous_year_value from SubmissionValue
- [ ] T101 [US6] Add CSS/styling for significant change highlighting in wizard views
- [ ] T102 [US6] Handle "First submission" case when no previous year exists
- [ ] T103 [US6] Run bin/rails test to verify all US6 tests pass

**Checkpoint**: User Story 6 complete - YoY comparison displayed with significant changes highlighted

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Code quality, locking mechanism, and final validation

- [ ] T104 Implement lock!/unlock! actions in app/controllers/submission_steps_controller.rb (FR-029)
- [ ] T105 Add routes for lock/unlock member actions in config/routes.rb
- [ ] T106 Update wizard views to show lock status and lock owner
- [ ] T107 [P] Add generated status to SUBMISSION_STATUSES in app/models/concerns/amsf_constants.rb
- [ ] T108 Implement submission locking after XBRL generation (FR-024)
- [ ] T109 Implement reopen! method in app/models/submission.rb (FR-025)
- [ ] T110 Add validation warnings display throughout wizard (FR-033, FR-034)
- [ ] T111 Block XBRL generation until all required elements valid (FR-035)
- [ ] T112 [P] Run bin/rubocop -a for code style compliance
- [ ] T113 Run bin/rails test to verify all tests pass
- [ ] T114 Run quickstart.md validation - manual test of complete wizard flow

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - US1 must complete first (defines wizard infrastructure)
  - US2-US4 can proceed in parallel after US1 (independent data capture)
  - US5-US6 enhance US1 wizard (can proceed in parallel)
- **Polish (Phase 9)**: Depends on US1 minimum (wizard must exist)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories - REQUIRED for MVP
- **User Story 2 (P2)**: Can start after US1 (uses wizard to verify data appears) - Independently testable
- **User Story 3 (P2)**: Can start after US1 (uses wizard to verify revenue stats) - Independently testable
- **User Story 4 (P3)**: Can start after US1 (uses wizard to verify training stats) - Independently testable
- **User Story 5 (P3)**: Can start after US1 (extends wizard step UI) - Independently testable
- **User Story 6 (P3)**: Can start after US1 (extends wizard step display) - Independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD)
- Models before services
- Services before controllers
- Controllers before views
- Core implementation before integration
- Run tests after each story to verify

### Parallel Opportunities

- Setup Phase: T002-T008 can all run in parallel (different migrations)
- Foundational Tests: T010-T015 can all run in parallel (different test files)
- Foundational Models: T016-T020 can all run in parallel (different model files)
- US1 Views: T044-T050 can all run in parallel (different step templates)
- US3/US4/US5/US6: Can be worked on in parallel by different developers after US1 completes
- View Components: T034-T035 can run in parallel with controller work

---

## Parallel Example: User Story 1 Implementation

```bash
# Launch all tests for User Story 1 together (FIRST - must fail):
Task: "Write failing test for extended CalculationEngine in test/services/calculation_engine_test.rb"
Task: "Write failing test for YearOverYearComparator in test/services/year_over_year_comparator_test.rb"
Task: "Write failing controller test for 7-step wizard in test/controllers/submission_steps_controller_test.rb"

# Launch all views for User Story 1 together (after controller done):
Task: "Create app/views/submission_steps/step_1.html.erb"
Task: "Create app/views/submission_steps/step_2.html.erb"
Task: "Create app/views/submission_steps/step_3.html.erb"
Task: "Create app/views/submission_steps/step_4.html.erb"
Task: "Create app/views/submission_steps/step_5.html.erb"
Task: "Create app/views/submission_steps/step_6.html.erb"
Task: "Create app/views/submission_steps/step_7.html.erb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (migrations, constants)
2. Complete Phase 2: Foundational (new models, extended validations)
3. Complete Phase 3: User Story 1 (7-step wizard with calculations)
4. **STOP and VALIDATE**: Test wizard end-to-end, generate XBRL
5. Deploy/demo if ready - this delivers core value proposition

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → **Deploy/Demo (MVP!)** - Wizard works
3. Add User Story 2 → Test independently → Deploy - Client compliance capture
4. Add User Story 3 → Test independently → Deploy - Property management
5. Add User Story 4 → Test independently → Deploy - Training records
6. Add User Story 5 → Test independently → Deploy - Override capability
7. Add User Story 6 → Test independently → Deploy - YoY comparison
8. Complete Polish → Final release

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Developer A: User Story 1 (critical path - wizard infrastructure)
3. Once US1 done:
   - Developer A: User Story 5 (override) + User Story 6 (YoY)
   - Developer B: User Story 2 (client form) + User Story 3 (managed properties)
   - Developer C: User Story 4 (trainings) + Polish
4. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- TDD REQUIRED: Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Total estimated tasks: 114
- Task count per story: Setup=9, Foundational=15, US1=29, US2=11, US3=12, US4=12, US5=8, US6=7, Polish=11
