# Implementation Plan: AMSF Taxonomy Compliance

**Branch**: `012-amsf-taxonomy-compliance` | **Date**: 2024-12-03 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/012-amsf-taxonomy-compliance/spec.md`

## Summary

Fix 21 invalid XBRL element names in CalculationEngine and 11 invalid category references in element mapping configuration to ensure generated XBRL output passes all compliance tests against the official AMSF taxonomy (323 elements). This includes implementing proper dimensional contexts for country breakdowns and correcting element type handling.

## Technical Context

**Language/Version**: Ruby 3.2+ / Rails 8.0
**Primary Dependencies**: Nokogiri (XML parsing), Minitest (testing), Jumpstart Pro (application framework)
**Storage**: PostgreSQL (primary), existing SubmissionValue model
**Testing**: Minitest with compliance test suite at `test/compliance/`
**Target Platform**: Web application (Linux server)
**Project Type**: Web (Rails monolith)
**Performance Goals**: Compliance tests execute in under 30 seconds
**Constraints**: Must not break existing data; backward-compatible SubmissionValue records
**Scale/Scope**: 323 taxonomy elements, 21 invalid element fixes, 11 mapping configuration fixes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-Driven Development (NON-NEGOTIABLE)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Tests exist before implementation | ✅ PASS | Comprehensive test suite already exists at `test/compliance/` (57 tests) |
| Red-Green-Refactor cycle | ✅ PASS | Tests currently fail (4 failures); implementation will make them pass |
| Coverage for new code | ✅ PASS | All changes validated by existing compliance tests |

### II. Code Quality & Simplicity

| Requirement | Status | Evidence |
|-------------|--------|----------|
| YAGNI | ✅ PASS | Only fixing invalid elements; no speculative features |
| Single Responsibility | ✅ PASS | CalculationEngine and XbrlGenerator maintain focused roles |
| RuboCop compliance | ⏳ VERIFY | Will run RuboCop on all changes |
| No commented-out code | ✅ PASS | Only removing/replacing invalid element names |

### III. Rails Conventions First

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Rails conventions | ✅ PASS | Following existing service object patterns |
| Jumpstart patterns | ✅ PASS | Account-scoped data access maintained |
| No new architectural patterns | ✅ PASS | Modifying existing services only |

### Security Standards

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Account scoping | ✅ PASS | Data remains scoped to organization |
| Parameter filtering | N/A | No new user inputs |
| SQL injection prevention | ✅ PASS | Existing parameterized queries maintained |

**Gate Status**: ✅ PASS - No constitution violations

## Project Structure

### Documentation (this feature)

```text
specs/012-amsf-taxonomy-compliance/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
app/
├── services/
│   ├── calculation_engine.rb      # Fix 21 invalid element names
│   └── xbrl_generator.rb          # Fix dimensional contexts, type handling
└── models/
    └── submission_value.rb        # No changes expected

config/
└── amsf_element_mapping.yml       # Restructure to remove invalid category keys

test/
├── compliance/                    # Existing tests (no changes)
│   ├── xbrl_taxonomy_test.rb
│   ├── xbrl_calculation_test.rb
│   ├── xbrl_structure_test.rb
│   ├── xbrl_type_test.rb
│   ├── xbrl_dimension_test.rb
│   └── element_mapping_test.rb
└── support/
    └── xbrl_test_helper.rb        # Existing helper (no changes)

docs/
├── gap_analysis.md                # Reference document (element mappings)
└── strix_Real_Estate_AML_CFT_survey_2025.xsd  # Authoritative taxonomy
```

**Structure Decision**: Single project (Rails monolith). All changes are within existing service objects and configuration files. No new directories or architectural patterns required.

## Complexity Tracking

No constitution violations requiring justification.

---

## Phase 0: Research

See [research.md](./research.md) for detailed findings.

### Research Tasks

1. **Element Name Mappings**: Extract exact old→new element mappings from gap_analysis.md
2. **Dimensional Context Pattern**: Research XBRL dimensional contexts for country breakdowns
3. **Element Type Registry**: Understand XbrlTestHelper's type detection for validation

### Key Decisions

| Decision | Rationale | Alternatives Rejected |
|----------|-----------|----------------------|
| Use gap_analysis.md as authoritative mapping source | Already contains validated old→new element mappings | Parsing XSD directly (more complex, same result) |
| Remove category keys from YAML entirely | Tests validate element names only, not structure | Keep categories with underscore prefix (still fails tests) |
| Use single `a1103` element with dimensional contexts | XBRL standard for country breakdowns | Keep underscore pattern (invalid per taxonomy) |

---

## Phase 1: Design

See [data-model.md](./data-model.md) for entity definitions.

### Changes Required

#### 1. CalculationEngine (21 element name fixes)

| Current (Invalid) | Correct | Description |
|-------------------|---------|-------------|
| `a1301` | `a12002B` | PEP clients |
| `a1502` | `a1502B` | PEP beneficial owners |
| `a2102` | `a2102B` | Purchase transactions |
| `a2103` | `a2105B` | Sale transactions |
| `a2104` | `a2107B` | Rental transactions |
| `a2105` | `a2102BB` | Purchase value |
| `a2106` | `a2105BB` | Sale value |
| `a2107` | `a2107BB` | Rental value |
| `a2201` | `a2203` | Cash transaction count |
| `a2301` | `a2501A` | Crypto transactions |
| `a2302` | `a2501A` | Crypto value (same element) |
| `a2401` | *(remove)* | PEP transactions (not in taxonomy) |
| `a1103_XX` | `a1103` + dimensional context | Country breakdown |

#### 2. Element Mapping YAML (11 category fixes)

Remove category wrapper keys and flatten structure:
- `entity_identification` → Remove (elements `a0101-a0104` not in taxonomy)
- `entity_info` → Remove (elements `a1001-a1003` not in taxonomy)
- `client_statistics` → Flatten to direct element keys
- `client_nationalities` → Remove (use dimensional contexts)
- `transaction_statistics` → Flatten and fix element names
- `payment_statistics` → Flatten and fix element names
- `str_statistics` → Flatten
- `kyc_procedures` → Rename to `aC` prefix elements
- `compliance_policies` → Rename to `aC` prefix elements
- `training` → Rename to `aC13xx` elements
- `monitoring` → Rename to `aC18xx` elements

#### 3. XbrlGenerator (dimensional contexts)

- Remove underscore-suffixed element pattern from `build_country_contexts`
- Implement proper `CountryDimension` with `a1103` base element
- Each country gets a dimensional context, `a1103` references it via `contextRef`

#### 4. Type Handling

- Boolean elements: Use `Oui`/`Non` (French)
- Monetary elements: Include `decimals` and `unitRef="EUR"`
- Integer elements: Include `unitRef="pure"`

---

## Next Steps

1. Run `/speckit.tasks` to generate task breakdown
2. Execute tasks following TDD (tests already failing, implement to make pass)
3. Verify all 57 compliance tests pass
4. Run RuboCop to ensure code quality
