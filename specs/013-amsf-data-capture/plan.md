# Implementation Plan: AMSF Survey Data Capture

**Branch**: `013-amsf-data-capture` | **Date**: 2025-12-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-amsf-data-capture/spec.md`

## Summary

Implement comprehensive data capture for AMSF annual survey submission, minimizing user effort by:
1. Extending existing models (Client, Transaction, BeneficialOwner) with compliance fields
2. Creating new models (ManagedProperty, Training) for property management and staff training
3. Extending CalculationEngine to compute all 323 XBRL elements from CRM data
4. Building a step-by-step submission wizard with pre-calculated values, override capability, and year-over-year comparison

The approach leverages existing Jumpstart Pro patterns, Hotwire for the wizard UI, and extends the existing XbrlGenerator and CalculationEngine services.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.0
**Primary Dependencies**: Jumpstart Pro, Hotwire (Turbo/Stimulus), Nokogiri (XML/XBRL), Pay gem
**Storage**: PostgreSQL (primary), existing schema with clients, transactions, submissions tables
**Testing**: Minitest with fixtures, Capybara for system tests
**Target Platform**: Web application (multi-tenant SaaS)
**Project Type**: Web application (monolithic Rails)
**Performance Goals**: Wizard completion under 15 minutes, calculation engine under 5 seconds
**Constraints**: Must integrate with existing Jumpstart Pro account model, AMSF XBRL taxonomy compliance
**Scale/Scope**: Single organization per submission, ~50-500 clients, ~100-1000 transactions per year

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (NON-NEGOTIABLE)

| Requirement | Compliance |
|-------------|------------|
| Red-Green-Refactor cycle | **WILL COMPLY** - All new models, services, and wizard steps will have tests written first |
| No implementation without failing tests | **WILL COMPLY** - Each PR will include failing tests before implementation |
| Test types by scope | **WILL COMPLY** - Unit tests for models/services, integration tests for wizard flow, system tests for end-to-end submission |
| Coverage expectations | **WILL COMPLY** - All new code will have test coverage |

### II. Code Quality & Simplicity

| Requirement | Compliance |
|-------------|------------|
| YAGNI | **WILL COMPLY** - Only implementing fields/features specified in requirements |
| Single Responsibility | **WILL COMPLY** - Separate services for calculations, wizard steps, XBRL generation |
| Meaningful naming | **WILL COMPLY** - Clear model/method names following existing patterns |
| RuboCop compliance | **WILL COMPLY** - All code must pass existing RuboCop configuration |
| No commented-out code | **WILL COMPLY** |
| Explicit over implicit | **WILL COMPLY** |

### III. Rails Conventions First

| Requirement | Compliance |
|-------------|------------|
| Convention over configuration | **WILL COMPLY** - Following Rails patterns |
| Jumpstart patterns | **WILL COMPLY** - Using account scoping, existing auth patterns |
| Hotwire by default | **WILL COMPLY** - Wizard uses Turbo Frames for step navigation |
| Fat models, skinny controllers | **WILL COMPLY** - Business logic in models/services |
| Concerns for shared behavior | **WILL COMPLY** - Reusing existing concerns |

### Security Standards

| Requirement | Compliance |
|-------------|------------|
| Pundit policies | **WILL COMPLY** - SubmissionPolicy for role-based access (FR-030, FR-031) |
| Account scoping | **WILL COMPLY** - All data scoped to current_account |
| Strong parameters | **WILL COMPLY** |
| SQL injection prevention | **WILL COMPLY** |

**Gate Status**: **PASSED** - No violations, proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/013-amsf-data-capture/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── wizard-api.md    # Wizard controller endpoints
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
# Rails application structure (existing)
app/
├── controllers/
│   └── submissions/
│       └── wizard_controller.rb    # NEW: Multi-step wizard
├── models/
│   ├── client.rb                   # EXTEND: Compliance fields
│   ├── transaction.rb              # EXTEND: Compliance fields
│   ├── beneficial_owner.rb         # EXTEND: Verification fields
│   ├── managed_property.rb         # NEW: Property management
│   ├── training.rb                 # NEW: Staff training
│   ├── submission.rb               # EXTEND: Lifecycle states
│   └── submission_value.rb         # EXTEND: Override tracking
├── services/
│   ├── calculation_engine.rb       # EXTEND: New calculations
│   └── year_over_year_comparator.rb # NEW: YoY comparison
├── policies/
│   └── submission_policy.rb        # EXTEND: Role-based access
├── views/
│   └── submissions/
│       └── wizard/                 # NEW: Wizard step views
└── components/
    ├── statistic_card_component.rb # NEW: Review UI
    └── statistic_group_component.rb # NEW: Grouped statistics

db/
└── migrate/
    ├── xxx_add_compliance_fields_to_clients.rb
    ├── xxx_add_compliance_fields_to_transactions.rb
    ├── xxx_add_verification_fields_to_beneficial_owners.rb
    ├── xxx_create_managed_properties.rb
    ├── xxx_create_trainings.rb
    └── xxx_add_lifecycle_to_submissions.rb

test/
├── models/
│   ├── managed_property_test.rb    # NEW
│   └── training_test.rb            # NEW
├── services/
│   ├── calculation_engine_test.rb  # EXTEND
│   └── year_over_year_comparator_test.rb # NEW
├── controllers/
│   └── submissions/
│       └── wizard_controller_test.rb # NEW
└── system/
    └── submission_wizard_test.rb   # NEW
```

**Structure Decision**: Following existing Rails/Jumpstart Pro conventions. New models in `app/models/`, wizard controller namespaced under `submissions/`, view components for reusable UI elements.

## Complexity Tracking

No violations requiring justification. All implementation follows standard Rails patterns with minimal complexity:
- Single database (PostgreSQL)
- Monolithic architecture (no microservices)
- Standard Rails MVC with existing service patterns
- Hotwire for dynamic UI (no SPA framework)
