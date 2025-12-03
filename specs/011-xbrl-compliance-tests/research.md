# Research: XBRL Compliance Test Suite

**Date**: December 2024
**Feature**: 011-xbrl-compliance-tests

## Research Questions

### 1. XSD Schema Parsing Approach

**Question**: How to efficiently parse the AMSF taxonomy XSD to extract element names and types?

**Decision**: Use Nokogiri with XPath queries

**Rationale**:
- Nokogiri is already a Rails dependency (used by XbrlGenerator)
- XPath provides precise targeting of `<element>` definitions
- The XSD file has 323 non-abstract elements, which is manageable in memory
- Parsing once at test suite startup and caching the result is efficient

**Implementation Pattern**:
```ruby
# Parse XSD and extract element definitions
doc = Nokogiri::XML(File.read("docs/strix_Real_Estate_AML_CFT_survey_2025.xsd"))
doc.remove_namespaces! # Simplify XPath queries

# Get all non-abstract elements
elements = doc.xpath("//element[@abstract='false']").map do |el|
  {
    name: el["name"],
    id: el["id"],
    type: el["type"] || extract_inline_type(el)
  }
end
```

**Alternatives Considered**:
- **XSD gem (xsd-reader)**: Provides typed schema parsing but adds external dependency; overkill for our needs
- **Manual regex parsing**: Fragile, error-prone for complex XML structures
- **Converting XSD to JSON**: Extra step with no benefit; Nokogiri handles XML directly

---

### 2. Element Type Categorization

**Question**: How to categorize elements for type-specific validation?

**Decision**: Create a type mapping based on XSD type definitions

**Rationale**:
The XSD uses these primary types:
- `xbrli:integerItemType` - Count values (clients, transactions)
- `xbrli:monetaryItemType` - EUR amounts
- `xbrli:stringItemType` - Free text fields
- Inline `enumeration` restrictions - Boolean-like fields (Oui/Non)

**Type Detection Logic**:
```ruby
def element_type(element_node)
  type_attr = element_node["type"]
  return :integer if type_attr&.include?("integerItemType")
  return :monetary if type_attr&.include?("monetaryItemType")
  return :string if type_attr&.include?("stringItemType")

  # Check for inline enumeration (Oui/Non booleans)
  if element_node.xpath(".//enumeration").any?
    return :enum
  end

  :unknown
end
```

**Validation Rules by Type**:
| Type | Unit | Format | Allowed Values |
|------|------|--------|----------------|
| integer | pure | Whole number | Any integer ≥ 0 |
| monetary | EUR | Decimal (2 places) | Any decimal |
| string | none | Any text | Any string |
| enum | none | Exact match | Defined values (e.g., "Oui", "Non") |

---

### 3. Test Organization Strategy

**Question**: How to organize tests for maintainability and independent execution?

**Decision**: Dedicated `test/compliance/` directory with focused test files

**Rationale**:
- Separates business-critical compliance tests from regular unit tests
- Allows running `bin/rails test test/compliance/` independently
- Each test file has single responsibility (aligns with constitution)
- Shared XSD parsing in `test/support/xbrl_test_helper.rb` avoids duplication

**Test File Structure**:
| File | Purpose | Spec Coverage |
|------|---------|---------------|
| `xbrl_taxonomy_test.rb` | Element name validation | US1, FR-001, FR-002 |
| `xbrl_structure_test.rb` | XML structure validation | US4, FR-006 |
| `xbrl_type_test.rb` | Data type conformance | US5, FR-003, FR-008 |
| `xbrl_calculation_test.rb` | Calculation accuracy | US3, FR-005 |
| `xbrl_dimension_test.rb` | Country contexts | US6, FR-007 |
| `element_mapping_test.rb` | YAML config validation | US7, FR-002 |
| `taxonomy_coverage_test.rb` | Coverage tracking | FR-011 |

---

### 4. XSD Parsing Performance

**Question**: How to handle the large XSD file (60K+ tokens) efficiently in tests?

**Decision**: Parse once at class level, memoize result

**Rationale**:
- XSD is static; no need to re-parse for each test
- Class-level memoization with `class << self` pattern
- Parsing takes ~50ms, acceptable for test setup
- Use Nokogiri's `remove_namespaces!` for simpler XPath queries

**Implementation**:
```ruby
module XbrlTestHelper
  class << self
    def taxonomy_elements
      @taxonomy_elements ||= parse_xsd
    end

    def valid_element_names
      @valid_element_names ||= taxonomy_elements.map { |e| e[:name] }.to_set
    end

    private

    def parse_xsd
      xsd_path = Rails.root.join("docs/strix_Real_Estate_AML_CFT_survey_2025.xsd")
      doc = Nokogiri::XML(File.read(xsd_path))
      doc.remove_namespaces!

      doc.xpath("//element[@abstract='false']").map do |el|
        { name: el["name"], id: el["id"], type: determine_type(el) }
      end
    end
  end
end
```

---

### 5. Calculation Test Data Strategy

**Question**: How to create deterministic test data for calculation validation?

**Decision**: Use dedicated fixtures with predictable values

**Rationale**:
- Existing fixtures may change; dedicated compliance fixtures are stable
- Each calculation scenario uses explicit, documented values
- Easier to verify expected results match actual

**Test Data Pattern**:
```ruby
# Create clients with known properties
def setup_calculation_scenario(natural_persons:, legal_entities:, peps:)
  org = organizations(:compliance_test_org)

  natural_persons.times { create_client(org, type: :natural_person) }
  legal_entities.times { create_client(org, type: :legal_entity) }
  peps.times { create_client(org, type: :natural_person, is_pep: true) }

  org
end
```

**Expected Calculations** (from spec):
| Scenario | Input | Element | Expected Value |
|----------|-------|---------|----------------|
| Client counts | 10 natural + 5 legal | a1101 | 15 |
| Client types | 10 natural + 5 legal | a1102 | 10 |
| Transaction totals | 3 txns @ 100K+200K+300K | a2104B | 600,000 |
| PEP clients | 2 PEP clients | a1301 | 2 |
| STR count | 1 STR in 2024 | a3101 | 1 |

---

### 6. Boolean/Enum Handling

**Question**: How to handle the French Oui/Non enum convention?

**Decision**: Validate exact string matching; update XbrlGenerator if needed

**Rationale**:
- The taxonomy uses `<enumeration value="Oui"/>` and `<enumeration value="Non"/>`
- Current XbrlGenerator uses "true"/"false" for boolean elements
- Tests should validate the correct convention; implementation fixes separately

**Findings from XSD**:
All boolean-like elements use this inline type:
```xml
<complexType>
  <simpleContent>
    <restriction base="xbrli:stringItemType">
      <enumeration value="Oui"/>
      <enumeration value="Non"/>
    </restriction>
  </simpleContent>
</complexType>
```

**Test Approach**:
```ruby
test "enum elements use Oui/Non values" do
  enum_elements = XbrlTestHelper.taxonomy_elements.select { |e| e[:type] == :enum }

  enum_elements.each do |element|
    generated_value = extract_value_from_xbrl(element[:name])
    assert_includes ["Oui", "Non"], generated_value,
      "Element #{element[:name]} should use Oui/Non, got: #{generated_value}"
  end
end
```

---

### 7. Dimensional Context Validation

**Question**: How to validate dimensional contexts for country breakdowns?

**Decision**: Check context structure and CountryDimension element presence

**Rationale**:
- Taxonomy defines `CountryDimension` as an abstract dimension item
- Country-specific facts must reference contexts with this dimension
- Context ID should encode the country code (e.g., `ctx_country_FR`)

**Validation Approach**:
```ruby
def validate_dimensional_context(xbrl_doc, country_code)
  context = xbrl_doc.at_xpath("//context[contains(@id, '#{country_code}')]")
  assert context, "Missing context for country #{country_code}"

  dimension = context.at_xpath(".//CountryDimension")
  assert dimension, "Context #{country_code} missing CountryDimension"
  assert_equal country_code, dimension.text
end
```

---

## Summary of Decisions

| Area | Decision | Key Benefit |
|------|----------|-------------|
| XSD Parsing | Nokogiri with XPath | No new dependencies; familiar API |
| Test Organization | `test/compliance/` directory | Independent execution; clear separation |
| Parsing Performance | Class-level memoization | Parse once; fast test runs |
| Type Detection | Inspect type attribute + inline enums | Accurate type categorization |
| Test Data | Dedicated fixtures | Deterministic, documented scenarios |
| Enum Handling | Validate Oui/Non exact match | Catches localization issues |
| Dimension Contexts | Check context structure | Validates country breakdowns |

## Next Steps

1. Phase 1: Create `data-model.md` with test helper design
2. Phase 1: Create `quickstart.md` with test execution instructions
3. Phase 2: Generate `tasks.md` with implementation tasks
