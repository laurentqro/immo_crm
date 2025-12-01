# Implementation Plan: Immo CRM MVP

**Branch**: `001-mvp-immo-crm` | **Date**: 2025-11-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-mvp-immo-crm/spec.md`

## Summary

**Immo CRM** is a mini-CRM for Monaco real estate agents that makes annual AMSF AML/CFT compliance effortless. The core value proposition is transforming 2 weeks of manual compliance work into a 15-minute review process.

**Technical Approach:**
- Rails 8 + Jumpstart Pro multi-tenant SaaS foundation
- Hotwire (Turbo + Stimulus) for dynamic UI without heavy JavaScript
- CRM-first architecture: Clients, Transactions, Beneficial Owners, STR Reports
- XBRL generation via Nokogiri (Ruby) with XULE validation via Python/Arelle sidecar
- 4-step annual submission wizard with auto-calculated aggregates

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.0
**Primary Dependencies**: Jumpstart Pro, Devise, Pundit, Hotwire (Turbo/Stimulus), Nokogiri, Pay gem
**Storage**: PostgreSQL 15+ (primary), SolidQueue (jobs), SolidCache (cache), SolidCable (websockets)
**Testing**: Minitest with parallel execution, Capybara + Selenium for system tests
**Target Platform**: Linux server (Hetzner CPX21), Web browser (desktop-first, mobile-responsive)
**Project Type**: Web application (monolithic Rails)
**Performance Goals**: <500ms page loads, XBRL generation <30s, validation <60s
**Constraints**: GDPR-compliant, 5-year data retention, single EU datacenter (Hetzner Falkenstein/Nuremberg)
**Scale/Scope**: Initial: 10-50 users, ~100 clients/org, ~50 transactions/year/org

**External Services:**
- Python validation sidecar (FastAPI + Arelle + XULE) - internal service
- Stripe (via Jumpstart Pro Pay gem) - billing
- No external CRM/compliance APIs in MVP

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (NON-NEGOTIABLE)

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Red-Green-Refactor mandatory | ✅ PASS | All features developed with failing tests first |
| Unit tests for models/services | ✅ PASS | `test/models/`, `test/services/` directories |
| Integration tests for controllers | ✅ PASS | `test/controllers/`, `test/integration/` |
| System tests for critical journeys | ✅ PASS | `test/system/` for submission wizard, client CRUD |
| New code has test coverage | ✅ PASS | CI blocks merge without passing tests |

### II. Code Quality & Simplicity

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| YAGNI - no speculative features | ✅ PASS | MVP scope strictly defined; Excel import deferred |
| Single Responsibility | ✅ PASS | Service objects for complex logic (CalculationEngine, XbrlGenerator) |
| RuboCop compliance | ✅ PASS | CI runs `bin/rubocop` on all PRs |
| No commented-out code | ✅ PASS | Enforced via code review |

### III. Rails Conventions First

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Convention over configuration | ✅ PASS | Standard Rails 8 patterns throughout |
| Jumpstart patterns | ✅ PASS | Account/User/Team from Jumpstart Pro; Organization extends Account |
| Hotwire by default | ✅ PASS | Turbo Frames for inline CRUD, Turbo Streams for real-time |
| Fat models, skinny controllers | ✅ PASS | Business logic in models + `app/services/` |
| Concerns for shared behavior | ✅ PASS | `AmsfConstants`, `Auditable` concerns |

### Security Standards

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Pundit policies for all resources | ✅ PASS | `app/policies/` for Client, Transaction, Submission, etc. |
| Account scoping enforced | ✅ PASS | All queries via `current_organization.X.find()` |
| Cross-tenant returns 404 | ✅ PASS | Never 403; hides resource existence |
| Strong parameters | ✅ PASS | All controllers use `params.require().permit()` |
| CSRF protection enabled | ✅ PASS | Default Rails CSRF; API endpoints use token auth |

**Constitution Check Result: ✅ ALL GATES PASS**

## Project Structure

### Documentation (this feature)

```text
specs/001-mvp-immo-crm/
├── plan.md              # This file
├── spec.md              # Feature specification (MVP design document)
├── research.md          # Phase 0 output - technology decisions
├── data-model.md        # Phase 1 output - entity relationships
├── quickstart.md        # Phase 1 output - developer setup guide
├── contracts/           # Phase 1 output - API contracts
│   └── api-v1.yml       # OpenAPI 3.0 specification
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
app/
├── controllers/
│   ├── dashboard_controller.rb
│   ├── clients_controller.rb
│   ├── beneficial_owners_controller.rb
│   ├── transactions_controller.rb
│   ├── str_reports_controller.rb
│   ├── settings_controller.rb
│   ├── submissions_controller.rb
│   └── submission_steps_controller.rb
│
├── models/
│   ├── organization.rb
│   ├── client.rb
│   ├── beneficial_owner.rb
│   ├── transaction.rb
│   ├── str_report.rb
│   ├── setting.rb
│   ├── submission.rb
│   ├── submission_value.rb
│   ├── audit_log.rb
│   └── concerns/
│       ├── amsf_constants.rb
│       └── auditable.rb
│
├── services/
│   ├── calculation_engine.rb
│   ├── xbrl_generator.rb
│   ├── validation_service.rb
│   └── submission_builder.rb
│
├── policies/
│   ├── client_policy.rb
│   ├── transaction_policy.rb
│   ├── submission_policy.rb
│   └── organization_policy.rb
│
├── views/
│   ├── dashboard/
│   ├── clients/
│   ├── transactions/
│   ├── submissions/
│   └── submission_steps/
│
└── javascript/controllers/
    ├── transaction_form_controller.js
    ├── client_search_controller.js
    └── validation_controller.js

config/
├── routes/
│   └── crm.rb           # CRM-specific routes
└── amsf_element_mapping.yml

db/
└── migrate/
    ├── YYYYMMDD_create_organizations.rb
    ├── YYYYMMDD_create_clients.rb
    ├── YYYYMMDD_create_beneficial_owners.rb
    ├── YYYYMMDD_create_transactions.rb
    ├── YYYYMMDD_create_str_reports.rb
    ├── YYYYMMDD_create_settings.rb
    ├── YYYYMMDD_create_submissions.rb
    ├── YYYYMMDD_create_submission_values.rb
    └── YYYYMMDD_create_audit_logs.rb

test/
├── models/
├── controllers/
├── services/
├── system/
│   ├── submission_wizard_test.rb
│   ├── client_management_test.rb
│   └── transaction_logging_test.rb
└── fixtures/

validation_service/          # Python sidecar
├── main.py
├── Dockerfile
├── requirements.txt
└── taxonomies/
    └── strix_Real_Estate_AML_CFT_survey_2025/
```

**Structure Decision**: Monolithic Rails application following Jumpstart Pro conventions. Python validation service deployed as a sidecar container via Kamal. No frontend/backend split - Hotwire provides sufficient interactivity.

## Complexity Tracking

> No constitution violations requiring justification.

| Decision | Rationale | Alternative Considered |
|----------|-----------|------------------------|
| Python sidecar for validation | Arelle/XULE only available in Python; no Ruby equivalent | Pure Ruby validation (insufficient - XULE rules required) |
| Single database | MVP scale doesn't require sharding | Multi-tenant database isolation (premature optimization) |
| Soft deletes for compliance | 5-year retention requirement | Hard deletes with backup restoration (operationally complex) |

## Phase Outputs

### Phase 0: Research (Complete)
See: [research.md](./research.md)

### Phase 1: Design (Complete)
See: [data-model.md](./data-model.md), [contracts/api-v1.yml](./contracts/api-v1.yml), [quickstart.md](./quickstart.md)

### Phase 2: Tasks
See: [tasks.md](./tasks.md) (generated by `/speckit.tasks`)
