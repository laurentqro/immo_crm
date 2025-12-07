# Implementation Plan: AMSF Survey Review Page

**Branch**: `015-amsf-survey-review` | **Date**: 2025-12-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/015-amsf-survey-review/spec.md`

## Summary

Replace the current 7-step submission wizard with a single-page survey review displaying all AMSF elements organized by questionnaire sections. Users can search/filter elements and complete submissions from this unified view. The implementation leverages existing `Xbrl::Taxonomy` and `ElementManifest` infrastructure, adding a new `Xbrl::Survey` module for questionnaire structure and a Stimulus controller for client-side filtering.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.0
**Primary Dependencies**: Hotwire (Turbo/Stimulus), TailwindCSS, Xbrl::Taxonomy, Xbrl::ElementManifest
**Storage**: PostgreSQL (existing Submission, SubmissionValue models)
**Testing**: Minitest with fixtures, system tests with Capybara
**Target Platform**: Web application (Rails server)
**Project Type**: Web application (Rails monolith with Jumpstart Pro)
**Performance Goals**: Search/filter responds instantly (<100ms perceived), page loads with 300+ elements smoothly
**Constraints**: Read-only for MVP (no inline editing), no lock/unlock system
**Scale/Scope**: ~300 XBRL elements, ~25 sections, single-page view

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-Driven Development | ✅ PASS | Plan includes TDD workflow for all new code |
| II. Code Quality & Simplicity | ✅ PASS | Single-page design, reuses existing ElementManifest |
| III. Rails Conventions First | ✅ PASS | Uses Hotwire, standard controller/view patterns |
| Security: Authorization | ✅ PASS | Pundit policies enforced in controller |
| Security: Account Scoping | ✅ PASS | Submissions scoped via policy_scope |
| Hotwire Architecture | ✅ PASS | Stimulus for filtering, standard Rails views |

**Gate Status**: PASS - No violations, no complexity justifications needed.

## Project Structure

### Documentation (this feature)

```text
specs/015-amsf-survey-review/
├── plan.md              # This file
├── research.md          # Phase 0 output (already complete from brainstorming)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (routes)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   └── survey_reviews_controller.rb    # NEW: Single-page review controller
├── javascript/
│   └── controllers/
│       └── survey_filter_controller.js # NEW: Client-side filtering
├── models/
│   ├── submission_value.rb             # MODIFY: Add needs_review? method
│   └── xbrl/
│       ├── element_manifest.rb         # MODIFY: Add needs_review to ElementValue
│       ├── survey.rb                   # NEW: Questionnaire structure
│       ├── taxonomy.rb                 # Existing
│       └── taxonomy_element.rb         # Existing
├── views/
│   └── survey_reviews/
│       ├── show.html.erb               # NEW: Main review page
│       └── _element_row.html.erb       # NEW: Element display partial
└── config/
    ├── routes.rb                       # MODIFY: Add review routes
    └── initializers/
        └── xbrl_taxonomy.rb            # MODIFY: Add Survey validation

test/
├── controllers/
│   └── survey_reviews_controller_test.rb  # NEW
├── models/
│   ├── submission_value_test.rb           # MODIFY: Add needs_review tests
│   └── xbrl/
│       ├── element_manifest_test.rb       # MODIFY: Add needs_review tests
│       └── survey_test.rb                 # NEW
└── system/
    └── survey_review_test.rb              # NEW: End-to-end flow
```

**Structure Decision**: Standard Rails monolith structure following Jumpstart Pro conventions. New controller and views under dedicated `survey_reviews` namespace to coexist with existing `submission_steps` until deprecation.

## Complexity Tracking

> No complexity violations to justify - design uses existing patterns and infrastructure.

---

## Phase 0: Research

**Status**: Complete (from brainstorming session)

Key decisions made:
1. **Single page vs tabs**: Single scrollable page chosen for simplicity and global search
2. **Filtering approach**: Client-side Stimulus for instant UX (all 300 elements already loaded)
3. **Module naming**: `Xbrl::Survey` for questionnaire structure
4. **ElementManifest reuse**: Delegate to existing abstraction rather than direct queries
5. **needs_review flag**: Stored in SubmissionValue.metadata, surfaced via ElementValue
6. **MVP scope**: Read-only display, no lock/unlock, no inline editing

See [docs/plans/2025-12-05-amsf-wizard-redesign.md](../../docs/plans/2025-12-05-amsf-wizard-redesign.md) for detailed design decisions.

---

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](data-model.md) for entity details.

**Key additions:**
- `Xbrl::Survey` module with SECTIONS constant
- `SubmissionValue#needs_review?` method
- `ElementValue#needs_review` attribute

### API Contracts

See [contracts/](contracts/) for route definitions.

**New routes:**
- `GET /submissions/:submission_id/review` → `survey_reviews#show`
- `POST /submissions/:submission_id/review/complete` → `survey_reviews#complete`

### Quickstart

See [quickstart.md](quickstart.md) for setup and testing instructions.
