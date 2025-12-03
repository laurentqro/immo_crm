# Implementation Plan: XBRL Compliance Test Suite

**Branch**: `011-xbrl-compliance-tests` | **Date**: December 2024 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-xbrl-compliance-tests/spec.md`

## Summary

Create a comprehensive test suite that validates XBRL output against the official AMSF taxonomy schema. The tests will:
1. Parse the XSD schema to extract authoritative element names and types
2. Validate that all generated elements exist in the taxonomy
3. Verify calculation accuracy with known test data
4. Ensure XBRL document structure compliance (namespaces, contexts, units)
5. Track taxonomy coverage percentage

This is the most critical test suite in the application - it ensures the core purpose (generating valid AMSF submissions) is achieved.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.0
**Primary Dependencies**: Minitest, Nokogiri (XSD/XML parsing), existing XbrlGenerator and CalculationEngine services
**Storage**: PostgreSQL (test database with fixtures)
**Testing**: Minitest with fixtures, parallel execution enabled
**Target Platform**: Rails application (Linux/macOS server)
**Project Type**: Web application (Rails monolith)
**Performance Goals**: Test suite executes in under 30 seconds
**Constraints**: Must parse large XSD file (60K+ tokens); tests must be deterministic and repeatable
**Scale/Scope**: Validate against 321 taxonomy elements; 10+ calculation scenarios

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (NON-NEGOTIABLE)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Red-Green-Refactor cycle | ✅ PASS | This IS the test suite itself - we're writing tests |
| Tests written before implementation | ✅ PASS | Tests will validate existing code and drive any fixes |
| Coverage expectations | ✅ PASS | Creates comprehensive test coverage for XBRL generation |

### II. Code Quality & Simplicity

| Requirement | Status | Notes |
|-------------|--------|-------|
| YAGNI | ✅ PASS | Only tests what spec requires; no speculative test infrastructure |
| Single Responsibility | ✅ PASS | Tests organized by validation type (schema, structure, calculation) |
| Meaningful naming | ✅ PASS | Test names will describe expected behavior |
| RuboCop compliance | ✅ PASS | All test code must pass RuboCop |

### III. Rails Conventions First

| Requirement | Status | Notes |
|-------------|--------|-------|
| Convention over configuration | ✅ PASS | Using standard Minitest patterns, fixtures |
| Testing patterns | ✅ PASS | Following Rails testing conventions in test/ directory |

### Security Standards

| Requirement | Status | Notes |
|-------------|--------|-------|
| Account scoping | ✅ PASS | Test fixtures use proper organization scoping |
| No security impact | ✅ PASS | Read-only tests, no new endpoints or data access |

**Gate Status**: ✅ PASS - All constitution requirements satisfied. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/011-xbrl-compliance-tests/
├── plan.md              # This file
├── research.md          # Phase 0 output - XSD parsing approach
├── data-model.md        # Phase 1 output - Test helper design
├── quickstart.md        # Phase 1 output - Running the tests
├── contracts/           # N/A (no API contracts for tests)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Rails application structure (existing)
app/
├── services/
│   ├── xbrl_generator.rb        # Existing - generates XBRL XML
│   └── calculation_engine.rb    # Existing - calculates values
config/
└── amsf_element_mapping.yml     # Existing - element mapping config

# Test structure (new files for this feature)
test/
├── services/
│   ├── xbrl_generator_test.rb   # Existing - enhance with compliance tests
│   └── calculation_engine_test.rb # Existing - enhance with accuracy tests
├── compliance/                   # NEW - dedicated compliance test directory
│   ├── xbrl_taxonomy_test.rb    # Schema validation tests
│   ├── xbrl_structure_test.rb   # Document structure tests
│   ├── xbrl_calculation_test.rb # Calculation accuracy tests
│   ├── element_mapping_test.rb  # YAML config validation tests
│   └── taxonomy_coverage_test.rb # Coverage tracking tests
└── support/
    └── xbrl_test_helper.rb      # NEW - shared XSD parsing utilities

# Reference files
docs/
├── strix_Real_Estate_AML_CFT_survey_2025.xsd  # Authoritative schema
└── gap_analysis.md                             # Known issues reference
```

**Structure Decision**: Adding a dedicated `test/compliance/` directory for high-level XBRL compliance tests. This separates business-critical compliance validation from unit tests, making the suite easy to run independently (`bin/rails test test/compliance/`).

## Complexity Tracking

No constitution violations requiring justification.
