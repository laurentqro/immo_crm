<!--
SYNC IMPACT REPORT
==================
Version change: N/A → 1.0.0 (Initial release)
Modified principles: None (new document)
Added sections:
  - Core Principles (3): TDD, Code Quality, Rails Conventions
  - Security Standards
  - Rails Conventions & Patterns
  - Governance
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (compatible - Constitution Check section exists)
  - .specify/templates/spec-template.md ✅ (compatible - Requirements section aligns)
  - .specify/templates/tasks-template.md ✅ (compatible - TDD workflow supported)
Follow-up TODOs: None
-->

# Immo CRM Constitution

## Core Principles

### I. Test-Driven Development (NON-NEGOTIABLE)

All feature development MUST follow the TDD discipline:

- **Red-Green-Refactor cycle is mandatory**: Tests MUST be written first, MUST fail before implementation, then minimal code written to pass
- **No implementation without failing tests**: Code changes that add functionality require corresponding tests written beforehand
- **Test types by scope**:
  - Unit tests for models, services, and isolated logic
  - Integration tests for controller actions and user flows
  - System tests for critical user journeys
- **Coverage expectations**: New code MUST have test coverage; legacy code changes SHOULD include tests for modified behavior

**Rationale**: TDD ensures design clarity, prevents regression, and documents expected behavior. Skipping tests creates compounding technical debt.

### II. Code Quality & Simplicity

Code MUST prioritize clarity and maintainability:

- **YAGNI (You Aren't Gonna Need It)**: Only implement what is explicitly required; no speculative features
- **Single Responsibility**: Each class, method, and module has one clear purpose
- **Meaningful naming**: Variables, methods, and classes MUST be self-documenting
- **RuboCop compliance**: All code MUST pass RuboCop checks (configured in `.rubocop.yml`)
- **No commented-out code**: Dead code MUST be removed, not commented
- **Explicit over implicit**: Prefer clarity over cleverness; code is read more than written

**Rationale**: Simple code is easier to test, debug, extend, and onboard new developers. Complexity MUST be justified.

### III. Rails Conventions First

Development MUST leverage Rails patterns and Jumpstart Pro architecture:

- **Convention over configuration**: Follow Rails conventions unless there's a documented, justified reason not to
- **Jumpstart patterns**: Use established patterns for accounts, billing, authentication as documented in CLAUDE.md
- **Hotwire by default**: Turbo Drive, Turbo Frames, and Turbo Streams for dynamic UI; Stimulus for JavaScript behavior
- **Fat models, skinny controllers**: Business logic belongs in models or service objects, not controllers
- **Concerns for shared behavior**: Use Rails concerns for cross-cutting model/controller behavior

**Rationale**: Rails conventions reduce cognitive load, improve onboarding, and ensure compatibility with the broader Rails ecosystem and Jumpstart Pro updates.

## Security Standards

All development MUST adhere to security best practices:

### Authentication & Authorization
- **Devise configuration**: MUST NOT weaken default security settings without documented approval
- **Pundit policies**: All controller actions accessing resources MUST have corresponding Pundit policies
- **Account scoping**: Multi-tenant data MUST be scoped to `current_account`; cross-account data access is forbidden

### Data Protection
- **Parameter filtering**: Sensitive parameters (passwords, tokens, keys) MUST be filtered from logs
- **Strong parameters**: All controller params MUST use strong parameters; no mass assignment vulnerabilities
- **SQL injection prevention**: MUST use parameterized queries; never interpolate user input into SQL

### OWASP Compliance
- **XSS prevention**: User-generated content MUST be escaped; `html_safe` requires explicit justification
- **CSRF protection**: MUST NOT disable CSRF protection on non-API endpoints
- **Session security**: Session configuration MUST use secure cookies in production

**Violation handling**: Security violations block merge; no exceptions without security review.

## Rails Conventions & Patterns

### Hotwire Architecture

- **Turbo Drive**: Enabled by default; opt-out specific links/forms only when necessary
- **Turbo Frames**: Use for partial page updates; name frames descriptively (e.g., `property_#{id}_details`)
- **Turbo Streams**: Use for real-time updates and multi-target responses; prefer over custom JavaScript
- **Stimulus controllers**: Small, focused controllers; one primary responsibility per controller

### Service Objects

When business logic exceeds simple model callbacks:

- **Location**: `app/services/` directory
- **Naming**: Verb-noun pattern (e.g., `CreateProperty`, `AssignAgent`)
- **Interface**: Single public `call` method; return Result object or raise on failure
- **Testing**: Unit tested in isolation with mocked dependencies

### View Components

For reusable UI elements:

- **Location**: `app/components/` directory
- **When to use**: UI that appears in 3+ places or has complex rendering logic
- **Testing**: Component tests for rendering and behavior

## Governance

### Amendment Process

1. **Proposal**: Document proposed change with rationale in PR description
2. **Review**: Changes require explicit approval from project lead
3. **Migration**: Breaking changes MUST include migration plan for existing code
4. **Version bump**: Update constitution version per semantic versioning rules

### Versioning Policy

- **MAJOR**: Principle removal or fundamental redefinition
- **MINOR**: New principle or section added; material expansion of existing guidance
- **PATCH**: Clarifications, wording improvements, typo fixes

### Compliance Verification

- **PR reviews**: All PRs MUST verify compliance with constitution principles
- **Automated checks**: RuboCop and test suite MUST pass before merge
- **Constitution check**: Implementation plans MUST include Constitution Check section

### Precedence

This constitution supersedes informal practices. When in conflict:
1. Constitution principles
2. CLAUDE.md guidance
3. Rails conventions
4. Team preferences

**Version**: 1.0.0 | **Ratified**: 2025-11-30 | **Last Amended**: 2025-11-30
