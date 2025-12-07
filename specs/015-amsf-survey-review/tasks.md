# Tasks: AMSF Survey Review Page

**Input**: Design documents from `/specs/015-amsf-survey-review/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Tests are included as this is a Rails application following TDD practices.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Rails app**: `app/`, `test/`, `config/` at repository root
- Models: `app/models/`
- Controllers: `app/controllers/`
- Views: `app/views/`
- Stimulus: `app/javascript/controllers/`
- Tests: `test/`

---

## Phase 1: Setup

**Purpose**: Project initialization and basic structure

- [x] T001 Create Xbrl::Survey module skeleton in app/models/xbrl/survey.rb
- [x] T002 [P] Add survey review routes to config/routes.rb

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### SubmissionValue Enhancement (TDD)

- [x] T003 Add test for `SubmissionValue#needs_review?` in test/models/submission_value_test.rb
- [x] T004 Add `needs_review?` method to SubmissionValue in app/models/submission_value.rb

### ElementManifest Enhancement (TDD)

- [x] T005 Add tests for ElementValue needs_review in test/models/xbrl/element_manifest_test.rb
- [x] T006 Add `needs_review` attribute to ElementValue in app/models/xbrl/element_manifest.rb
- [x] T007 [P] Update `element_with_value` to populate needs_review in app/models/xbrl/element_manifest.rb

### Xbrl::Survey Module (TDD)

- [x] T008 [P] Add test for `Xbrl::Survey.sections` in test/models/xbrl/survey_test.rb
- [x] T009 [P] Add test for `Xbrl::Survey.elements_for` in test/models/xbrl/survey_test.rb
- [x] T010 [P] Add test for `Xbrl::Survey.validate!` in test/models/xbrl/survey_test.rb
- [x] T011 Populate SECTIONS constant with all 45 AMSF questionnaire sections in app/models/xbrl/survey.rb
- [x] T012 [P] Implement `Xbrl::Survey.sections` class method in app/models/xbrl/survey.rb
- [x] T013 [P] Implement `Xbrl::Survey.elements_for` class method in app/models/xbrl/survey.rb
- [x] T014 [P] Implement `Xbrl::Survey.validate!` class method in app/models/xbrl/survey.rb
- [x] T015 Add boot-time validation to config/initializers/xbrl_taxonomy.rb

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Review All Survey Elements (Priority: P1) 🎯 MVP

**Goal**: Display all AMSF survey elements on a single scrollable page organized by official questionnaire sections

**Independent Test**: Navigate to a submission's review page and verify all elements are displayed organized by AMSF sections with their calculated values

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T016 [P] [US1] Controller test for GET /submissions/:id/review in test/controllers/survey_reviews_controller_test.rb
- [x] T017 [P] [US1] Controller test for authentication requirement in test/controllers/survey_reviews_controller_test.rb
- [x] T018 [P] [US1] Controller test for authorization (access denied) in test/controllers/survey_reviews_controller_test.rb

### Implementation for User Story 1

- [x] T019 [US1] Create SurveyReviewsController with show action in app/controllers/survey_reviews_controller.rb
- [x] T020 [US1] Implement `set_submission` and `authorize_submission` before_actions in app/controllers/survey_reviews_controller.rb
- [x] T021 [US1] Implement `ensure_values_calculated` method in app/controllers/survey_reviews_controller.rb
- [x] T022 [US1] Implement `build_sections_with_elements` method in app/controllers/survey_reviews_controller.rb
- [x] T023 [US1] Create main review page view in app/views/survey_reviews/show.html.erb
- [x] T024 [P] [US1] Create element row partial (showing label, code, value, source) in app/views/survey_reviews/_element_row.html.erb
- [x] T025 [P] [US1] Create section header partial in app/views/survey_reviews/_section.html.erb
- [x] T026 [US1] Style section headers and element rows with TailwindCSS in app/views/survey_reviews/show.html.erb
- [x] T027 [US1] Add fixture for submission_values with review flags in test/fixtures/submission_values.yml

**Checkpoint**: User Story 1 complete - all elements display on single scrollable page organized by sections

---

## Phase 4: User Story 2 - Search Survey Elements (Priority: P1)

**Goal**: Allow users to search for specific survey elements by name or label

**Independent Test**: Type a search term and verify only matching elements are displayed with non-matching elements hidden

### Tests for User Story 2

- [x] T028 [P] [US2] System test for search functionality in test/system/survey_review_test.rb

### Implementation for User Story 2

- [x] T029 [US2] Create survey_filter Stimulus controller in app/javascript/controllers/survey_filter_controller.js
- [x] T030 [US2] Implement text search filtering logic in app/javascript/controllers/survey_filter_controller.js
- [x] T031 [US2] Add search input field to view in app/views/survey_reviews/show.html.erb
- [x] T032 [US2] Add data-controller and data-target attributes for Stimulus in app/views/survey_reviews/show.html.erb
- [x] T033 [US2] Implement element count display in app/javascript/controllers/survey_filter_controller.js
- [x] T034 [US2] Implement section header hiding when no visible elements in app/javascript/controllers/survey_filter_controller.js

**Checkpoint**: User Story 2 complete - search instantly filters elements and updates count

---

## Phase 5: User Story 3 - Filter Elements Needing Review (Priority: P2)

**Goal**: Allow users to filter to show only elements flagged for review

**Independent Test**: Enable the "needs review only" filter and verify only flagged elements are displayed

### Tests for User Story 3

- [x] T035 [P] [US3] System test for needs review filter in test/system/survey_review_test.rb

### Implementation for User Story 3

- [x] T036 [US3] Add "Needs review only" toggle to view in app/views/survey_reviews/show.html.erb
- [x] T037 [US3] Implement needs_review filter logic in app/javascript/controllers/survey_filter_controller.js
- [x] T038 [US3] Add visual highlight styling for flagged elements (background color, badge) in app/views/survey_reviews/_element_row.html.erb
- [x] T039 [US3] Add "Review" badge to section headers containing flagged elements in app/views/survey_reviews/_section.html.erb
- [x] T040 [US3] Combine text search and needs_review filter in app/javascript/controllers/survey_filter_controller.js

**Checkpoint**: User Story 3 complete - users can filter to flagged elements with visual highlighting

---

## Phase 6: User Story 4 - Complete Submission (Priority: P1)

**Goal**: Allow users to complete a submission from the review page

**Independent Test**: Click "Complete Submission" button, confirm, and verify submission status changes to completed

### Tests for User Story 4

- [x] T041 [P] [US4] Controller test for POST /submissions/:id/review/complete in test/controllers/survey_reviews_controller_test.rb
- [x] T042 [P] [US4] Controller test for completing already-completed submission in test/controllers/survey_reviews_controller_test.rb
- [x] T043 [P] [US4] System test for end-to-end completion flow in test/system/survey_review_test.rb

### Implementation for User Story 4

- [x] T044 [US4] Implement complete action in app/controllers/survey_reviews_controller.rb
- [x] T045 [US4] Add "Complete Submission" button to bottom of review page in app/views/survey_reviews/show.html.erb
- [x] T046 [US4] Add confirmation dialog before completion (Turbo confirm) in app/views/survey_reviews/show.html.erb
- [x] T047 [US4] Hide complete button if submission already completed in app/views/survey_reviews/show.html.erb
- [x] T048 [US4] Display current status for completed submissions in app/views/survey_reviews/show.html.erb

**Checkpoint**: User Story 4 complete - submissions can be completed from review page with confirmation

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T049 [P] Run full test suite to verify all tests pass via bin/rails test
- [x] T050 [P] Run RuboCop and fix any style issues via bin/rubocop
- [x] T051 Validate quickstart.md instructions work end-to-end
- [x] T052 [P] System test for edge case: no search results in test/system/survey_review_test.rb
- [x] T053 [P] System test for edge case: no flagged elements with filter enabled in test/system/survey_review_test.rb
- [x] T054 Verify Xbrl::Survey.validate! runs successfully at boot

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - US1 (P1): Review All Elements - MVP foundation
  - US2 (P1): Search Elements - depends on US1 view being complete
  - US3 (P2): Filter Needs Review - depends on US2 Stimulus controller
  - US4 (P1): Complete Submission - can run parallel with US2/US3
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Depends on US1 view structure - builds on show.html.erb
- **User Story 3 (P2)**: Depends on US2 Stimulus controller - extends survey_filter_controller.js
- **User Story 4 (P1)**: Can start after US1 - independent of US2/US3

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Controller before views
- Views before Stimulus (for US2/US3)
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- T003, T005 can run in parallel (different test files)
- T008, T009, T010 can run in parallel (independent test cases)
- T012, T013, T014 can run in parallel (independent methods)
- Controller tests (T016, T017, T018) can run in parallel
- View partials (T024, T025) can run in parallel
- US4 can be worked on in parallel with US2/US3 by different developers

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch tests in parallel first:
Task: "Add test for SubmissionValue#needs_review?" [T003]
Task: "Add tests for ElementValue needs_review" [T005]

# Then implement to make tests pass:
Task: "Add needs_review? method to SubmissionValue" [T004]
Task: "Add needs_review attribute to ElementValue" [T006]

# Launch Survey tests in parallel:
Task: "Add test for Xbrl::Survey.sections" [T008]
Task: "Add test for Xbrl::Survey.elements_for" [T009]
Task: "Add test for Xbrl::Survey.validate!" [T010]

# Then implement Survey methods in parallel:
Task: "Implement Xbrl::Survey.sections" [T012]
Task: "Implement Xbrl::Survey.elements_for" [T013]
Task: "Implement Xbrl::Survey.validate!" [T014]
```

## Parallel Example: User Story 1

```bash
# Launch all controller tests together:
Task: "Controller test for GET /submissions/:id/review" [T016]
Task: "Controller test for authentication requirement" [T017]
Task: "Controller test for authorization (access denied)" [T018]

# Launch view partials in parallel:
Task: "Create element row partial" [T024]
Task: "Create section header partial" [T025]
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready - basic review page works

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Search works → Deploy/Demo
4. Add User Story 3 → Filtering works → Deploy/Demo
5. Add User Story 4 → Completion works → Deploy/Demo
6. Each story adds value without breaking previous stories

### Recommended Order

For a single developer working sequentially:
1. **US1** (Review All Elements) - establishes the page structure
2. **US4** (Complete Submission) - critical action, independent of filtering
3. **US2** (Search Elements) - adds Stimulus foundation
4. **US3** (Filter Needs Review) - extends Stimulus controller

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- AMSF section mapping (T011) requires referencing official PDF questionnaire
- No database migrations needed - uses existing SubmissionValue.metadata JSONB
