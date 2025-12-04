# Research: AMSF Taxonomy Compliance

**Branch**: `012-amsf-taxonomy-compliance`
**Date**: 2024-12-03

## Research Tasks

### 1. Element Name Mappings

**Source**: `docs/gap_analysis.md` (authoritative mapping document)

#### Invalid Elements in CalculationEngine

The following element names are currently used in `app/services/calculation_engine.rb` but don't exist in the AMSF taxonomy:

| Current (Invalid) | Correct Taxonomy Element | Method | Line Context |
|-------------------|--------------------------|--------|--------------|
| `a1301` | `a12002B` | `client_statistics` | PEP clients count |
| `a1401` | *(semantic mismatch)* | `client_statistics` | Currently "high-risk clients" - needs clarification |
| `a1502` | `a1502B` | `beneficial_owner_statistics` | PEP beneficial owners |
| `a2102` | `a2102B` | `transaction_statistics` | Purchase transactions count |
| `a2103` | `a2105B` | `transaction_statistics` | Sale transactions count |
| `a2104` | `a2107B` | `transaction_statistics` | Rental transactions count |
| `a2105` | `a2102BB` | `transaction_values` | Purchase value (EUR) |
| `a2106` | `a2105BB` | `transaction_values` | Sale value (EUR) |
| `a2107` | `a2107BB` | `transaction_values` | Rental value (EUR) |
| `a2201` | `a2203` | `payment_method_statistics` | Cash transaction count |
| `a2301` | `a2501A` | `payment_method_statistics` | Crypto transaction count |
| `a2302` | *(combine with a2501A)* | `payment_method_statistics` | Crypto value - taxonomy has single element |
| `a2401` | *(remove)* | `pep_transaction_statistics` | Not in taxonomy |
| `a1103_XX` | `a1103` + dimensional context | `client_nationality_breakdown` | Country breakdown |

#### Valid Elements (No Changes Needed)

These elements are already correct and should not be modified:

- `a1101` - Total number of clients
- `a1102` - Natural persons (nationals)
- `a11502B` - Legal entity clients
- `a11802B` - Trust clients
- `a1501` - Total beneficial owners
- `a2101B` - Total transactions
- `a2104B` - Total transaction value
- `a2202` - Cash amount (EUR)
- `a3101` - STRs filed

### 2. XBRL Dimensional Contexts for Country Breakdowns

**Decision**: Replace `a1103_XX` pattern with proper XBRL dimensional contexts

**Current Implementation** (invalid):
```ruby
# client_nationality_breakdown method generates:
result["a1103_FR"] = count  # Invalid - element doesn't exist
result["a1103_GB"] = count  # Invalid - element doesn't exist
```

**Correct XBRL Pattern**:
```xml
<!-- Define dimensional context for each country -->
<context id="ctx_country_FR">
  <entity>
    <identifier scheme="http://amsf.mc/rci">123456</identifier>
    <segment>
      <strix:CountryDimension>FR</strix:CountryDimension>
    </segment>
  </entity>
  <period><instant>2024-12-31</instant></period>
</context>

<!-- Use base element a1103 with contextRef to dimensional context -->
<strix:a1103 contextRef="ctx_country_FR" unitRef="unit_pure">42</strix:a1103>
<strix:a1103 contextRef="ctx_country_GB" unitRef="unit_pure">18</strix:a1103>
```

**Implementation Approach**:
1. CalculationEngine generates country breakdown using a single element name `a1103` with metadata indicating country
2. XbrlGenerator creates dimensional contexts for each unique country
3. Facts reference `a1103` element but point to country-specific contexts via `contextRef`

### 3. Element Type Registry

**Source**: `test/support/xbrl_test_helper.rb`

The `XbrlTestHelper` module provides:
- `element_types` hash mapping element names to type symbols (`:integer`, `:monetary`, `:enum`, `:string`)
- `enum_values` hash mapping enum element names to allowed values array

**Type Handling Requirements**:

| Type | Attributes Required | Value Format |
|------|---------------------|--------------|
| `:integer` | `unitRef="unit_pure"` | Whole number |
| `:monetary` | `unitRef="unit_EUR"`, `decimals="2"` | Decimal with 2 places |
| `:enum` | None | Exact match from allowed values |
| `:string` | None | Text content |

**French Boolean Convention**:
- Enum elements with `[Oui, Non]` allowed values must use French words
- Current code uses `true`/`false` - must change to `Oui`/`Non`

### 4. Element Mapping Configuration

**Source**: `config/amsf_element_mapping.yml`

**Problem**: Tests validate that each top-level key is a valid taxonomy element name. Current structure uses category wrapper keys:

```yaml
# Current (invalid) - category keys fail validation
entity_identification:  # ← Not a valid element name
  a0101:
    description: "..."
```

**Solution**: Restructure to flat element-keyed format, removing non-taxonomy elements:

```yaml
# Correct - only valid taxonomy element names as keys
a1101:
  description: "Total number of clients"
  source: calculated
  type: integer

a1102:
  description: "Number of natural person clients"
  source: calculated
  type: integer
```

**Elements to Remove** (not in taxonomy):
- `a0101` through `a0104` (entity identification)
- `a1001` through `a1003` (entity info)
- `a4101` through `a4206` (should be `aCxxxx`)
- `a5101` through `a5104` (should be `aC13xx`)
- `a6101` through `a6103` (should be `aC18xx`)

## Key Decisions

| # | Decision | Rationale | Alternatives Rejected |
|---|----------|-----------|----------------------|
| 1 | Use gap_analysis.md mappings | Already validated against XSD; provides exact old→new pairs | Parsing XSD directly (same result, more complex) |
| 2 | Flatten YAML structure | Test validates top-level keys; categories break validation | Underscore-prefix categories (still fails) |
| 3 | Single `a1103` with dimensional contexts | XBRL standard for dimensional data | Underscore suffix pattern (not valid XBRL) |
| 4 | Remove `a2401` (PEP transactions) | Element doesn't exist in taxonomy | Keep and map to alternate (no equivalent exists) |
| 5 | Use `Oui`/`Non` for French booleans | Taxonomy enumeration requires French | English true/false (fails type validation) |
| 6 | Store country code in metadata, not element name | Enables proper dimensional context generation | In-element-name storage (invalid XBRL) |

## Unresolved Items

None - all NEEDS CLARIFICATION items have been resolved through gap analysis document and taxonomy inspection.

## References

- `docs/gap_analysis.md` - Authoritative element mapping document
- `docs/strix_Real_Estate_AML_CFT_survey_2025.xsd` - Official AMSF taxonomy
- `test/support/xbrl_test_helper.rb` - Type detection and validation utilities
- `test/compliance/` - Compliance test suite (57 tests)
