# Tasks: Immo CRM MVP

**Input**: Design documents from `/specs/001-mvp-immo-crm/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/api-v1.yml
**Branch**: `001-mvp-immo-crm`
**Date**: 2025-11-30

**Tests**: TDD is **mandatory** per Constitution (Principle I). Tests MUST be written first and fail before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, shared models, and infrastructure that all user stories depend on.

- [X] T001 Verify Jumpstart Pro installation and run `bin/setup`
- [X] T002 [P] Add `discard` gem to Gemfile for soft deletes
- [X] T003 [P] Create `app/models/concerns/amsf_constants.rb` with all enums
- [X] T004 [P] Create `app/models/concerns/auditable.rb` concern for audit logging
- [X] T005 Generate Organization model: `bin/rails g model Organization account:references name:string rci_number:string country:string`
- [X] T006 Create migration `db/migrate/YYYYMMDD_create_organizations.rb` with indexes
- [X] T007 [P] Create `app/models/organization.rb` with validations and associations
- [X] T008 [P] Create `app/policies/organization_policy.rb` with Pundit authorization
- [X] T009 Create migration `db/migrate/YYYYMMDD_create_audit_logs.rb` with polymorphic structure
- [X] T010 [P] Create `app/models/audit_log.rb` with associations
- [X] T011 Run migrations and verify schema: `bin/rails db:migrate`
- [X] T012 [P] Configure CRM routes in `config/routes/crm.rb`
- [X] T013 [P] Create `config/amsf_element_mapping.yml` with XBRL element definitions
- [X] T014 Create `app/controllers/concerns/organization_scoped.rb` for tenant isolation
- [X] T015 [P] Add `current_organization` helper to `ApplicationController`

**Checkpoint**: ✅ Foundation ready - Jumpstart Pro configured, Organization model working, routes defined.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T016 Create fixtures for testing in `test/fixtures/organizations.yml`
- [ ] T017 [P] Create fixtures `test/fixtures/accounts.yml` extending Jumpstart fixtures
- [ ] T018 [P] Create fixtures `test/fixtures/users.yml` for test users
- [ ] T019 Create `test/test_helper.rb` additions for organization-scoped tests
- [ ] T020 [P] Create `test/models/organization_test.rb` with validation tests
- [ ] T021 [P] Create `test/policies/organization_policy_test.rb`
- [ ] T022 Run tests and verify green: `bin/rails test`
- [ ] T023 [P] Create base Stimulus controller structure in `app/javascript/controllers/`
- [ ] T024 [P] Configure Turbo Frame naming conventions in `app/helpers/turbo_helper.rb`

**Checkpoint**: Foundation ready - tests passing, organization scoping verified, Stimulus ready.

---

## Phase 3: User Story 1 - Dashboard & Onboarding (Priority: P0) 🎯 MVP

**Goal**: Users can sign up, create organization, see dashboard with stats.

**Independent Test**: Can sign up, complete onboarding wizard, see empty dashboard with "add client" prompt.

### Tests for User Story 1 ⚠️

> **TDD: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T025 [P] [US1] Create `test/system/onboarding_test.rb` with signup → organization → dashboard flow
- [ ] T026 [P] [US1] Create `test/controllers/dashboard_controller_test.rb` with auth and stats tests
- [ ] T027 [P] [US1] Create `test/integration/organization_setup_test.rb`

### Implementation for User Story 1

- [ ] T028 [US1] Create `app/controllers/onboarding_controller.rb` for setup wizard
- [ ] T029 [US1] Create `app/views/onboarding/` templates (entity_info, policies steps)
- [ ] T030 [P] [US1] Create `app/controllers/dashboard_controller.rb` with index action
- [ ] T031 [US1] Create `app/views/dashboard/index.html.erb` with stats panels
- [ ] T032 [P] [US1] Create `app/views/dashboard/_stats_panel.html.erb` partial
- [ ] T033 [P] [US1] Create `app/views/dashboard/_recent_transactions.html.erb` partial
- [ ] T034 [US1] Add dashboard stats calculation methods to `Organization` model
- [ ] T035 [US1] Create `app/javascript/controllers/onboarding_controller.js` for wizard
- [ ] T036 [US1] Verify tests pass: `bin/rails test test/system/onboarding_test.rb test/controllers/dashboard_controller_test.rb`

**Checkpoint**: Users can sign up, complete onboarding, see dashboard. US1 independently testable.

---

## Phase 4: User Story 2 - Client Management (Priority: P0)

**Goal**: Users can create, view, edit, delete clients with beneficial owners.

**Independent Test**: Can add client (natural person), add legal entity with beneficial owners, search/filter client list.

### Tests for User Story 2 ⚠️

> **TDD: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T037 [P] [US2] Create `test/models/client_test.rb` with validations, scopes, soft delete tests
- [ ] T038 [P] [US2] Create `test/models/beneficial_owner_test.rb` with validations
- [ ] T039 [P] [US2] Create `test/controllers/clients_controller_test.rb` with CRUD tests
- [ ] T040 [P] [US2] Create `test/controllers/beneficial_owners_controller_test.rb`
- [ ] T041 [P] [US2] Create `test/policies/client_policy_test.rb` with tenant isolation tests
- [ ] T042 [P] [US2] Create `test/system/client_management_test.rb` with Turbo Frame tests

### Implementation for User Story 2

- [ ] T043 [US2] Create migration `db/migrate/YYYYMMDD_create_clients.rb`
- [ ] T044 [US2] Create migration `db/migrate/YYYYMMDD_create_beneficial_owners.rb`
- [ ] T045 [US2] Run migrations: `bin/rails db:migrate`
- [ ] T046 [P] [US2] Create `app/models/client.rb` with validations, scopes, Discard
- [ ] T047 [P] [US2] Create `app/models/beneficial_owner.rb` with validations
- [ ] T048 [P] [US2] Create `app/policies/client_policy.rb` with organization scoping
- [ ] T049 [P] [US2] Create `app/policies/beneficial_owner_policy.rb`
- [ ] T050 [US2] Create `app/controllers/clients_controller.rb` with CRUD actions
- [ ] T051 [US2] Create `app/controllers/beneficial_owners_controller.rb` (nested)
- [ ] T052 [P] [US2] Create `app/views/clients/index.html.erb` with search and filters
- [ ] T053 [P] [US2] Create `app/views/clients/_client.html.erb` partial with Turbo Frame
- [ ] T054 [P] [US2] Create `app/views/clients/show.html.erb` with beneficial owners section
- [ ] T055 [P] [US2] Create `app/views/clients/_form.html.erb` with conditional fields
- [ ] T056 [P] [US2] Create `app/views/beneficial_owners/_form.html.erb`
- [ ] T057 [US2] Create `app/javascript/controllers/client_search_controller.js`
- [ ] T058 [US2] Create `app/javascript/controllers/client_form_controller.js` for PEP/legal type fields
- [ ] T059 [US2] Create fixtures `test/fixtures/clients.yml` and `test/fixtures/beneficial_owners.yml`
- [ ] T060 [US2] Verify all US2 tests pass: `bin/rails test test/models/client_test.rb test/models/beneficial_owner_test.rb test/controllers/clients_controller_test.rb test/system/client_management_test.rb`

**Checkpoint**: Full client management working. US2 independently testable.

---

## Phase 5: User Story 3 - Transaction Management (Priority: P0)

**Goal**: Users can log transactions (purchases, sales, rentals) with payment details.

**Independent Test**: Can create transaction linked to client, filter by type/year/payment, view transaction details.

### Tests for User Story 3 ⚠️

> **TDD: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T061 [P] [US3] Create `test/models/transaction_test.rb` with validations, scopes
- [ ] T062 [P] [US3] Create `test/models/str_report_test.rb` with validations
- [ ] T063 [P] [US3] Create `test/controllers/transactions_controller_test.rb`
- [ ] T064 [P] [US3] Create `test/controllers/str_reports_controller_test.rb`
- [ ] T065 [P] [US3] Create `test/system/transaction_logging_test.rb` with Turbo Frame tests

### Implementation for User Story 3

- [ ] T066 [US3] Create migration `db/migrate/YYYYMMDD_create_transactions.rb`
- [ ] T067 [US3] Create migration `db/migrate/YYYYMMDD_create_str_reports.rb`
- [ ] T068 [US3] Run migrations: `bin/rails db:migrate`
- [ ] T069 [P] [US3] Create `app/models/transaction.rb` with validations, scopes, Discard
- [ ] T070 [P] [US3] Create `app/models/str_report.rb` with validations, Discard
- [ ] T071 [P] [US3] Create `app/policies/transaction_policy.rb`
- [ ] T072 [P] [US3] Create `app/policies/str_report_policy.rb`
- [ ] T073 [US3] Create `app/controllers/transactions_controller.rb` with CRUD
- [ ] T074 [US3] Create `app/controllers/str_reports_controller.rb` with CRUD
- [ ] T075 [P] [US3] Create `app/views/transactions/index.html.erb` with filters
- [ ] T076 [P] [US3] Create `app/views/transactions/_transaction.html.erb` partial
- [ ] T077 [P] [US3] Create `app/views/transactions/_form.html.erb` with client selector
- [ ] T078 [P] [US3] Create `app/views/str_reports/index.html.erb`
- [ ] T079 [P] [US3] Create `app/views/str_reports/_form.html.erb`
- [ ] T080 [US3] Create `app/javascript/controllers/transaction_form_controller.js` for payment method
- [ ] T081 [US3] Create fixtures `test/fixtures/transactions.yml` and `test/fixtures/str_reports.yml`
- [ ] T082 [US3] Update dashboard to show recent transactions (integrate with US1)
- [ ] T083 [US3] Verify all US3 tests pass: `bin/rails test test/models/transaction_test.rb test/controllers/transactions_controller_test.rb test/system/transaction_logging_test.rb`

**Checkpoint**: Full transaction management working. US3 independently testable.

---

## Phase 6: User Story 4 - Settings & Policies (Priority: P0)

**Goal**: Users can configure entity info and compliance policies that persist across submissions.

**Independent Test**: Can edit entity info, toggle compliance settings, see settings grouped by category.

### Tests for User Story 4 ⚠️

> **TDD: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T084 [P] [US4] Create `test/models/setting_test.rb` with type casting, uniqueness tests
- [ ] T085 [P] [US4] Create `test/controllers/settings_controller_test.rb`
- [ ] T086 [P] [US4] Create `test/system/settings_test.rb` with category tabs tests

### Implementation for User Story 4

- [ ] T087 [US4] Create migration `db/migrate/YYYYMMDD_create_settings.rb` with unique index
- [ ] T088 [US4] Run migration: `bin/rails db:migrate`
- [ ] T089 [P] [US4] Create `app/models/setting.rb` with typed_value method, categories
- [ ] T090 [P] [US4] Create `app/policies/setting_policy.rb`
- [ ] T091 [US4] Create `app/controllers/settings_controller.rb` with batch update
- [ ] T092 [P] [US4] Create `app/views/settings/index.html.erb` with category tabs
- [ ] T093 [P] [US4] Create `app/views/settings/_entity_info.html.erb` partial
- [ ] T094 [P] [US4] Create `app/views/settings/_kyc_procedures.html.erb` partial
- [ ] T095 [P] [US4] Create `app/views/settings/_compliance_policies.html.erb` partial
- [ ] T096 [P] [US4] Create `app/views/settings/_training.html.erb` partial
- [ ] T097 [US4] Create `app/services/settings_seeder.rb` for default settings on org creation
- [ ] T098 [US4] Create fixtures `test/fixtures/settings.yml`
- [ ] T099 [US4] Verify all US4 tests pass: `bin/rails test test/models/setting_test.rb test/controllers/settings_controller_test.rb test/system/settings_test.rb`

**Checkpoint**: Settings management working. US4 independently testable.

---

## Phase 7: User Story 5 - Annual Submission Wizard (Priority: P0) 🎯 Full MVP

**Goal**: Users can complete 4-step annual submission and download validated XBRL file.

**Independent Test**: Can start submission, review aggregates, confirm policies, answer questions, validate, download XBRL.

### Tests for User Story 5 ⚠️

> **TDD: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T100 [P] [US5] Create `test/models/submission_test.rb` with state machine tests
- [ ] T101 [P] [US5] Create `test/models/submission_value_test.rb`
- [ ] T102 [P] [US5] Create `test/services/calculation_engine_test.rb` with aggregate calculations
- [ ] T103 [P] [US5] Create `test/services/xbrl_generator_test.rb` with XML output validation
- [ ] T104 [P] [US5] Create `test/services/validation_service_test.rb` with mock HTTP
- [ ] T105 [P] [US5] Create `test/controllers/submissions_controller_test.rb`
- [ ] T106 [P] [US5] Create `test/controllers/submission_steps_controller_test.rb`
- [ ] T107 [P] [US5] Create `test/system/submission_wizard_test.rb` with full flow

### Implementation for User Story 5

- [ ] T108 [US5] Create migration `db/migrate/YYYYMMDD_create_submissions.rb` with unique index
- [ ] T109 [US5] Create migration `db/migrate/YYYYMMDD_create_submission_values.rb`
- [ ] T110 [US5] Run migrations: `bin/rails db:migrate`
- [ ] T111 [P] [US5] Create `app/models/submission.rb` with state machine, uniqueness validation
- [ ] T112 [P] [US5] Create `app/models/submission_value.rb` with sources
- [ ] T113 [P] [US5] Create `app/policies/submission_policy.rb`
- [ ] T114 [US5] Create `app/services/calculation_engine.rb` with client/transaction stats
- [ ] T115 [US5] Create `app/services/xbrl_generator.rb` with Nokogiri XML builder
- [ ] T116 [US5] Create `app/services/validation_service.rb` for Python sidecar HTTP calls
- [ ] T117 [US5] Create `app/services/submission_builder.rb` to orchestrate submission creation
- [ ] T118 [US5] Create `app/controllers/submissions_controller.rb` with create, show, download
- [ ] T119 [US5] Create `app/controllers/submission_steps_controller.rb` for wizard steps
- [ ] T120 [P] [US5] Create `app/views/submissions/index.html.erb` for submission history
- [ ] T121 [P] [US5] Create `app/views/submissions/show.html.erb` for submission overview
- [ ] T122 [P] [US5] Create `app/views/submission_steps/step_1.html.erb` - Review Aggregates
- [ ] T123 [P] [US5] Create `app/views/submission_steps/step_2.html.erb` - Confirm Policies
- [ ] T124 [P] [US5] Create `app/views/submission_steps/step_3.html.erb` - Fresh Questions
- [ ] T125 [P] [US5] Create `app/views/submission_steps/step_4.html.erb` - Validate & Download
- [ ] T126 [US5] Create `app/javascript/controllers/validation_controller.js` for progress display
- [ ] T127 [US5] Create fixtures `test/fixtures/submissions.yml` and `test/fixtures/submission_values.yml`
- [ ] T128 [US5] Verify all US5 tests pass: `bin/rails test test/services/ test/controllers/submissions_controller_test.rb test/system/submission_wizard_test.rb`

**Checkpoint**: Full submission wizard working. US5 independently testable. **FULL MVP COMPLETE**.

---

## Phase 8: Python Validation Service

**Purpose**: Deploy XULE validation sidecar for XBRL file validation.

- [ ] T129 Create `validation_service/requirements.txt` with FastAPI, Arelle dependencies
- [ ] T130 Create `validation_service/main.py` FastAPI application with /validate and /health endpoints
- [ ] T131 Create `validation_service/Dockerfile` with Arelle and XULE plugin
- [ ] T132 Copy AMSF taxonomy files to `validation_service/taxonomies/`
- [ ] T133 [P] Test validation service locally: `docker build -t immo-validator . && docker run -p 8000:8000 immo-validator`
- [ ] T134 [P] Create `test/services/validation_service_integration_test.rb` with real HTTP calls (skip in CI)
- [ ] T135 Update `config/deploy.yml` (Kamal) with validator accessory configuration

**Checkpoint**: Validation service deployed and integrated.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories.

- [ ] T136 [P] Add help text tooltips throughout forms
- [ ] T137 [P] Create `app/views/shared/_strix_upload_guide.html.erb`
- [ ] T138 [P] Add loading states for Turbo Frame transitions
- [ ] T139 [P] Improve error messages for validation failures
- [ ] T140 [P] Add flash message styling for success/error states
- [ ] T141 Create `app/jobs/purge_expired_records_job.rb` for 5-year retention cleanup
- [ ] T142 [P] Add audit logging callbacks to Client, Transaction, Submission models
- [ ] T143 [P] Create `app/views/audit_logs/index.html.erb` for compliance viewing
- [ ] T144 Run full test suite: `bin/rails test`
- [ ] T145 Run RuboCop and fix issues: `bin/rubocop -a`
- [ ] T146 Run security scan: `bundle exec brakeman`
- [ ] T147 Performance check: verify <500ms page loads
- [ ] T148 Create seed data for demo: `db/seeds/demo.rb`

**Checkpoint**: Polish complete. Production-ready MVP.

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ─────────────────────────────────────────────┐
         │                                                    │
         ▼                                                    │
Phase 2 (Foundational) ──────────────────────────────────────┤
         │                                                    │
         ▼                                                    │
    ┌────┴────┬────────────┬────────────┐                    │
    │         │            │            │                    │
    ▼         ▼            ▼            ▼                    │
 Phase 3   Phase 4      Phase 5      Phase 6                 │
  (US1)     (US2)        (US3)        (US4)                  │
Dashboard  Clients   Transactions  Settings                   │
    │         │            │            │                    │
    └─────────┴────────────┴────────────┘                    │
                     │                                        │
                     ▼                                        │
              Phase 7 (US5)                                   │
          Submission Wizard ◄─────────────────────────────────┘
          (depends on US2, US3, US4 for data)
                     │
                     ▼
              Phase 8 (Validator)
                     │
                     ▼
              Phase 9 (Polish)
```

### User Story Dependencies

- **US1 (Dashboard)**: Can start after Phase 2 - No dependencies on other stories
- **US2 (Clients)**: Can start after Phase 2 - No dependencies on other stories
- **US3 (Transactions)**: Can start after Phase 2 - Benefits from US2 (client selector) but testable independently
- **US4 (Settings)**: Can start after Phase 2 - No dependencies on other stories
- **US5 (Submission)**: Depends on US2, US3, US4 for data to aggregate - Should start last

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Models before controllers
3. Controllers before views
4. Core implementation before Stimulus controllers
5. Verify tests pass before marking story complete

### Parallel Opportunities

**Phase 1 parallel tasks**: T002, T003, T004, T007, T008, T010, T012, T013, T015
**Phase 2 parallel tasks**: T017, T018, T020, T021, T023, T024
**US1 parallel tasks**: T025, T026, T027, T030, T032, T033
**US2 parallel tasks**: T037-T042 (tests), T046-T049 (models/policies), T052-T056 (views)
**US3 parallel tasks**: T061-T065 (tests), T069-T072 (models/policies), T075-T079 (views)
**US4 parallel tasks**: T084-T086 (tests), T089-T090 (models/policies), T092-T096 (views)
**US5 parallel tasks**: T100-T107 (tests), T111-T113 (models/policies), T120-T125 (views)

---

## Parallel Example: User Story 2 (Clients)

```bash
# Step 1: Launch all tests in parallel (TDD - write first, watch fail)
bin/rails test test/models/client_test.rb          # T037
bin/rails test test/models/beneficial_owner_test.rb # T038
bin/rails test test/controllers/clients_controller_test.rb # T039
# ... all should FAIL (red)

# Step 2: Run migrations
bin/rails db:migrate  # T043-T045

# Step 3: Launch models and policies in parallel
# T046: app/models/client.rb
# T047: app/models/beneficial_owner.rb
# T048: app/policies/client_policy.rb
# T049: app/policies/beneficial_owner_policy.rb

# Step 4: Verify model tests pass (green)
bin/rails test test/models/

# Step 5: Controllers (sequential - depend on models)
# T050: app/controllers/clients_controller.rb
# T051: app/controllers/beneficial_owners_controller.rb

# Step 6: Launch views in parallel
# T052-T056: all view files can be created in parallel

# Step 7: Verify all US2 tests pass
bin/rails test test/models/client_test.rb test/controllers/clients_controller_test.rb test/system/client_management_test.rb
```

---

## Implementation Strategy

### MVP First (User Stories 1-4 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3-6: US1-US4 (can parallelize)
4. **STOP and VALIDATE**: Basic CRM working (clients, transactions, settings)
5. Deploy preview to staging

### Full MVP (Add User Story 5)

1. After US1-US4 validated
2. Complete Phase 7: US5 (Submission Wizard)
3. Complete Phase 8: Validation Service
4. Complete Phase 9: Polish
5. **FINAL VALIDATION**: Complete submission flow working
6. Deploy to production

### Incremental Delivery

| Milestone | User Stories | What Works |
|-----------|--------------|------------|
| M1: CRM Foundation | US1 | Sign up, dashboard, organization |
| M2: Client Management | US1 + US2 | + Client CRUD, beneficial owners |
| M3: Transaction Logging | US1-US3 | + Transaction CRUD, STR reports |
| M4: Settings Complete | US1-US4 | + Compliance settings |
| M5: **Full MVP** | US1-US5 | + Submission wizard, XBRL download |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- **TDD is mandatory**: Verify tests fail (red) before implementing (green)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

---

## Summary

| Metric | Count |
|--------|-------|
| **Total Tasks** | 148 |
| **Phase 1 (Setup)** | 15 |
| **Phase 2 (Foundational)** | 9 |
| **US1 (Dashboard)** | 12 |
| **US2 (Clients)** | 24 |
| **US3 (Transactions)** | 23 |
| **US4 (Settings)** | 16 |
| **US5 (Submission)** | 29 |
| **Phase 8 (Validator)** | 7 |
| **Phase 9 (Polish)** | 13 |
| **Parallel Opportunities** | 85+ tasks marked [P] |
