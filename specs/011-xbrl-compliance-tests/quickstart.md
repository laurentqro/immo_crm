# Quickstart: XBRL Compliance Test Suite

**Date**: December 2024
**Feature**: 011-xbrl-compliance-tests

## Running the Tests

### Run All Compliance Tests

```bash
bin/rails test test/compliance/
```

### Run Specific Test Files

```bash
# Taxonomy validation (element names exist in XSD)
bin/rails test test/compliance/xbrl_taxonomy_test.rb

# Structure validation (namespaces, contexts, units)
bin/rails test test/compliance/xbrl_structure_test.rb

# Type conformance (integer, monetary, enum)
bin/rails test test/compliance/xbrl_type_test.rb

# Calculation accuracy (known data → expected values)
bin/rails test test/compliance/xbrl_calculation_test.rb

# Dimensional contexts (country breakdowns)
bin/rails test test/compliance/xbrl_dimension_test.rb

# YAML mapping validation
bin/rails test test/compliance/element_mapping_test.rb

# Coverage tracking
bin/rails test test/compliance/taxonomy_coverage_test.rb
```

### Run with Verbose Output

```bash
bin/rails test test/compliance/ -v
```

## Test Coverage Report

After running the coverage test, a summary is output:

```text
=== XBRL Taxonomy Coverage Report ===
Total taxonomy elements: 323
Mapped elements: 49
Coverage: 15.2%

By Section:
  Tab 1 (Customer Risk): 8 / 104 (7.7%)
  Tab 2 (Products/Services): 3 / 37 (8.1%)
  Tab 3 (Distribution): 1 / 44 (2.3%)
  Tab 4 (Controls): 0 / 105 (0.0%)
  Signatories: 0 / 2 (0.0%)
```

## Understanding Test Failures

### Invalid Element Name

```text
XbrlTaxonomyTest#test_all_generated_elements_exist_in_taxonomy
Expected element 'a2401' to exist in taxonomy
Did you mean: a2401B?
```

**Fix**: Update element name in `config/amsf_element_mapping.yml` or `app/services/calculation_engine.rb`

### Type Mismatch

```text
XbrlTypeTest#test_integer_elements_have_whole_number_values
Element 'a1101' expected integer, got: "15.0"
```

**Fix**: Ensure value is formatted as integer (no decimal point) in XbrlGenerator

### Missing Context Reference

```text
XbrlStructureTest#test_all_facts_have_valid_context_ref
Element 'a1103_FR' references context 'ctx_country_FR' which does not exist
```

**Fix**: Ensure XbrlGenerator creates dimensional contexts for all country codes

### Enum Value Mismatch

```text
XbrlTypeTest#test_enum_elements_use_correct_values
Element 'a11001BTOLA' should be 'Oui' or 'Non', got: 'true'
```

**Fix**: Update XbrlGenerator to use French boolean values (Oui/Non) instead of true/false

## Prerequisites

1. **Taxonomy files in docs/**:
   - `strix_Real_Estate_AML_CFT_survey_2025.xsd` (required)
   - Supporting linkbase files (optional)

2. **Test database prepared**:
   ```bash
   bin/rails db:test:prepare
   ```

3. **Fixtures loaded**:
   Tests use standard Rails fixtures from `test/fixtures/`

## Adding New Element Mappings

When adding support for new XBRL elements:

1. Add element to `config/amsf_element_mapping.yml`
2. Implement calculation in `app/services/calculation_engine.rb`
3. Run taxonomy test to verify element name is correct:
   ```bash
   bin/rails test test/compliance/xbrl_taxonomy_test.rb
   ```
4. Run type test to verify formatting:
   ```bash
   bin/rails test test/compliance/xbrl_type_test.rb
   ```

## CI Integration

Add to your CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run XBRL Compliance Tests
  run: bin/rails test test/compliance/
```

These tests should run on every PR to prevent compliance regressions.
