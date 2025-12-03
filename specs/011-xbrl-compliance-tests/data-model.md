# Data Model: XBRL Compliance Test Suite

**Date**: December 2024
**Feature**: 011-xbrl-compliance-tests

## Overview

This feature creates a test suite, not new data models. This document describes the **test helper infrastructure** that will be created to support compliance testing.

## Test Helper Design

### XbrlTestHelper Module

**Location**: `test/support/xbrl_test_helper.rb`

**Purpose**: Shared utilities for parsing the XSD taxonomy and validating XBRL output.

```ruby
module XbrlTestHelper
  # === Class Methods (parsed once, cached) ===

  # Returns Array of element definitions from XSD
  # Each element: { name:, id:, type:, allowed_values: }
  def self.taxonomy_elements

  # Returns Set of valid element names for O(1) lookup
  def self.valid_element_names

  # Returns Hash mapping element name to type symbol
  # Types: :integer, :monetary, :string, :enum
  def self.element_types

  # Returns Hash mapping enum element names to allowed values
  # e.g., { "a11001BTOLA" => ["Oui", "Non"] }
  def self.enum_values

  # === Instance Methods (for test classes) ===

  # Parse generated XBRL XML string into Nokogiri document
  def parse_xbrl(xml_string)

  # Extract all element names from generated XBRL
  def extract_element_names(xbrl_doc)

  # Get value of specific element from XBRL document
  def extract_element_value(xbrl_doc, element_name)

  # Validate element has correct contextRef
  def assert_valid_context_ref(xbrl_doc, element_name)

  # Validate element has correct unitRef
  def assert_valid_unit_ref(xbrl_doc, element_name, expected_unit)
end
```

### Taxonomy Element Structure

Each parsed element from the XSD:

| Field | Type | Description |
|-------|------|-------------|
| `name` | String | Element name (e.g., "a1101", "a11001BTOLA") |
| `id` | String | XSD element ID (e.g., "strix_a1101") |
| `type` | Symbol | `:integer`, `:monetary`, `:string`, `:enum` |
| `allowed_values` | Array | For enums only (e.g., ["Oui", "Non"]) |

### Type Mapping Logic

| XSD Type | Ruby Symbol | Unit | Example Elements |
|----------|-------------|------|------------------|
| `xbrli:integerItemType` | `:integer` | pure | a1101, a1102, a2101B |
| `xbrli:monetaryItemType` | `:monetary` | EUR | a1106B, a2104B |
| `xbrli:stringItemType` | `:string` | none | a11006 |
| Inline `<enumeration>` | `:enum` | none | a11001BTOLA, a11201BCD |

## Test Fixture Design

### Compliance Test Fixtures

**Location**: `test/fixtures/` (existing files, new records)

**Purpose**: Predictable test data for calculation verification.

#### Organizations Fixture Addition

```yaml
# test/fixtures/organizations.yml
compliance_test_org:
  name: "Compliance Test Org"
  rci_number: "99MC12345"
  # Standard Jumpstart Pro account association...
```

#### Clients for Calculation Tests

| Fixture Key | Type | Is PEP | Nationality | Purpose |
|-------------|------|--------|-------------|---------|
| `calc_natural_1` to `calc_natural_10` | natural_person | false | various | Count verification |
| `calc_legal_1` to `calc_legal_5` | legal_entity | false | MC | Legal entity count |
| `calc_pep_1`, `calc_pep_2` | natural_person | true | FR | PEP count |
| `calc_trust_1` | trust | false | MC | Trust count |

#### Transactions for Calculation Tests

| Fixture Key | Amount | Type | Payment Method | Purpose |
|-------------|--------|------|----------------|---------|
| `calc_txn_1` | 100,000 | purchase | bank | Sum to 600K |
| `calc_txn_2` | 200,000 | purchase | bank | Sum verification |
| `calc_txn_3` | 300,000 | sale | bank | Sum verification |
| `calc_txn_cash` | 50,000 | purchase | cash | Cash transaction count |

## Test Class Hierarchy

```
ActiveSupport::TestCase
└── XbrlComplianceTestCase (optional base class)
    ├── XbrlTaxonomyTest
    ├── XbrlStructureTest
    ├── XbrlTypeTest
    ├── XbrlCalculationTest
    ├── XbrlDimensionTest
    ├── ElementMappingTest
    └── TaxonomyCoverageTest
```

### XbrlComplianceTestCase Base Class (Optional)

**Location**: `test/compliance/xbrl_compliance_test_case.rb`

```ruby
class XbrlComplianceTestCase < ActiveSupport::TestCase
  include XbrlTestHelper

  def setup
    @organization = organizations(:compliance_test_org)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # Generate XBRL for a submission with calculated values
  def generate_xbrl_for(submission)
    CalculationEngine.new(submission).populate_submission_values!
    XbrlGenerator.new(submission).generate
  end
end
```

## Validation Results Structure

Tests should produce clear, actionable error messages:

```ruby
# Example validation result format
{
  status: :failed,
  errors: [
    {
      type: :invalid_element,
      element: "a2401",
      message: "Element 'a2401' not found in taxonomy",
      suggestion: "Did you mean 'a2401B'?"
    },
    {
      type: :type_mismatch,
      element: "a1101",
      expected_type: :integer,
      actual_value: "15.0",
      message: "Expected integer, got decimal value"
    }
  ]
}
```

## Coverage Tracking

### Coverage Report Structure

```ruby
# TaxonomyCoverageTest output format
{
  total_taxonomy_elements: 323,
  mapped_elements: 49,  # Elements in amsf_element_mapping.yml
  coverage_percentage: 15.2,
  unmapped_elements: [...],  # List of elements not yet mapped
  sections: {
    "Tab 1: Customer Risk" => { total: 104, mapped: 8 },
    "Tab 2: Products/Services" => { total: 37, mapped: 3 },
    "Tab 3: Distribution" => { total: 44, mapped: 1 },
    "Tab 4: Controls" => { total: 105, mapped: 0 },
    "Signatories" => { total: 2, mapped: 0 }
  }
}
```

## Dependencies

### Existing Code Used

| Component | Location | Usage |
|-----------|----------|-------|
| XbrlGenerator | `app/services/xbrl_generator.rb` | Subject under test |
| CalculationEngine | `app/services/calculation_engine.rb` | Subject under test |
| Element Mapping | `config/amsf_element_mapping.yml` | Validation target |
| Taxonomy XSD | `docs/strix_Real_Estate_AML_CFT_survey_2025.xsd` | Authoritative source |

### No New Production Dependencies

This feature only adds test code. No new gems or production code changes required for the test suite itself. (Any bugs found will be fixed separately.)
