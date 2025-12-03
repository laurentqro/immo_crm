# Feature Specification: XBRL Compliance Test Suite

**Feature Branch**: `011-xbrl-compliance-tests`
**Created**: December 2024
**Status**: Draft
**Input**: User description: "Based on the XBRL taxonomy files in docs/ and docs/gap_analysis.md, write automated tests that check that our generated XBRL file answers all the questions, and that all the mappings are correct. The most important set of tests in our app, that ensures our app is doing what it's supposed to do, at a high level."

## User Scenarios & Testing

### User Story 1 - Taxonomy Compliance Validation (Priority: P1)

As a compliance officer generating the annual AMSF survey, I need confidence that every generated XBRL file contains valid element names that match the official AMSF taxonomy schema, so that my submission won't be rejected by the regulator.

**Why this priority**: This is the foundational requirement - if element names don't match the taxonomy, the entire submission is invalid and will be rejected. The gap analysis revealed that 78% of our original element names were wrong.

**Independent Test**: Can be fully tested by generating an XBRL file and validating all element names against the XSD schema. Delivers immediate value by catching invalid element names before submission.

**Acceptance Scenarios**:

1. **Given** a submission with calculated values, **When** XBRL is generated, **Then** every element name in the output exists in the `strix_Real_Estate_AML_CFT_survey_2025.xsd` taxonomy schema
2. **Given** the taxonomy defines 321 elements, **When** the application's element mapping is analyzed, **Then** no unmapped elements exist in our `amsf_element_mapping.yml` that don't appear in the taxonomy
3. **Given** elements with specific suffixes (B, W, BB, BW, R, TOLA), **When** these elements are used, **Then** they match the semantic meaning defined in the taxonomy (BY clients vs WITH clients)

---

### User Story 2 - Complete Survey Coverage (Priority: P1)

As a real estate agent, I need the system to generate values for all required survey questions, so that my annual submission is complete and I don't receive compliance notices for missing data.

**Why this priority**: A submission missing required elements is incomplete. The gap analysis identified that we only covered ~3.4% of the 321 taxonomy elements.

**Independent Test**: Can be tested by generating a submission with representative data and checking that all mandatory sections have corresponding values. Delivers value by ensuring submissions are complete.

**Acceptance Scenarios**:

1. **Given** the taxonomy has 4 main tabs (Customer Risk, Products/Services, Distribution Risk, Controls), **When** a complete submission is generated, **Then** each tab has the minimum required elements populated
2. **Given** Tab 1 (Customer Risk) has 104 elements, **When** client and transaction data exists, **Then** client statistics, nationality breakdowns, and PEP exposure elements are populated
3. **Given** Tab 4 (Controls) has 105 `aCxxxx` elements, **When** organization settings exist, **Then** governance, compliance, and training elements are populated
4. **Given** a submission is finalized, **When** the XBRL is exported, **Then** no required elements have empty or null values

---

### User Story 3 - Calculation Accuracy (Priority: P1)

As an organization, I need the statistical calculations to accurately reflect my CRM data, so that my AMSF submission contains truthful figures and I remain compliant with anti-money laundering regulations.

**Why this priority**: Incorrect calculations could lead to regulatory penalties or reputational damage. This validates that our CalculationEngine produces correct aggregates.

**Independent Test**: Can be tested by creating known data sets and verifying that calculations match expected values exactly. Delivers value by ensuring data integrity.

**Acceptance Scenarios**:

1. **Given** 10 natural person clients and 5 legal entity clients, **When** calculations run, **Then** `a1101` = 15, `a1102` = 10, `a11502B` = 5
2. **Given** 3 transactions worth 100K, 200K, and 300K EUR, **When** calculations run, **Then** `a2101B` = 3 and `a2104B` = 600,000
3. **Given** 2 PEP clients with 5 transactions total, **When** calculations run, **Then** `a1301` = 2 and `a2401` = 5
4. **Given** 1 STR report filed on 2024-06-15, **When** calculating 2024 submission, **Then** `a3101` = 1

---

### User Story 4 - XBRL Structure Validity (Priority: P2)

As a submission system, I need generated XBRL files to be structurally valid XML with correct namespaces, contexts, and units, so that automated validators can process my submission.

**Why this priority**: XBRL validators check structure before content. Invalid structure means immediate rejection.

**Independent Test**: Can be tested by validating generated XML against XBRL 2.1 specification requirements. Delivers value by ensuring files are parseable.

**Acceptance Scenarios**:

1. **Given** any generated XBRL file, **When** parsed as XML, **Then** the document is well-formed with no XML errors
2. **Given** XBRL namespaces are required, **When** XBRL is generated, **Then** the document includes xbrl, link, xlink, iso4217, and strix namespaces
3. **Given** facts require context references, **When** facts are generated, **Then** every fact has a valid `contextRef` pointing to an existing context
4. **Given** numeric facts require unit references, **When** monetary facts are generated, **Then** they reference the EUR unit; **When** count facts are generated, **Then** they reference the pure unit

---

### User Story 5 - Element Type Conformance (Priority: P2)

As a validation system, I need each XBRL element to have the correct data type (integer, monetary, boolean, enum), so that values are properly interpreted.

**Why this priority**: The taxonomy defines strict types for each element. Type mismatches cause validation failures.

**Independent Test**: Can be tested by checking each generated element's value format against its taxonomy-defined type. Delivers value by catching type errors.

**Acceptance Scenarios**:

1. **Given** element `a1101` is defined as `xbrli:integerItemType`, **When** generated, **Then** its value is a whole number without decimals
2. **Given** element `a1106B` is defined as `xbrli:monetaryItemType`, **When** generated, **Then** its value has a `unitRef` to EUR and a `decimals` attribute
3. **Given** element `a11001BTOLA` is an enum with values [Oui, Non], **When** generated, **Then** its value is exactly "Oui" or "Non"
4. **Given** boolean elements follow Oui/Non convention, **When** generated, **Then** French boolean values are used (not true/false)

---

### User Story 6 - Dimensional Context Handling (Priority: P2)

As a submission requiring country breakdowns, I need nationality statistics to use dimensional contexts correctly, so that country-specific data is properly attributed.

**Why this priority**: The taxonomy uses XBRL dimensions for country breakdowns. Incorrect dimension usage makes the data unusable.

**Independent Test**: Can be tested by generating submissions with multi-nationality clients and verifying dimensional context structure. Delivers value by ensuring geographic data is valid.

**Acceptance Scenarios**:

1. **Given** clients from France and Germany, **When** XBRL is generated, **Then** separate dimensional contexts exist for FR and DE
2. **Given** dimensional contexts use CountryDimension, **When** a country-specific fact is generated, **Then** it references the correct dimensional context
3. **Given** country codes must be ISO 3166-1 alpha-2, **When** nationality data is processed, **Then** only valid 2-letter country codes are used

---

### User Story 7 - Mapping Consistency (Priority: P3)

As a developer maintaining the system, I need the element mapping configuration to be consistent with actual taxonomy elements, so that updates to the taxonomy can be tracked and validated.

**Why this priority**: The gap analysis revealed significant mapping inconsistencies. Maintaining mapping integrity prevents regression.

**Independent Test**: Can be tested by comparing `amsf_element_mapping.yml` against the XSD schema programmatically. Delivers value by maintaining mapping integrity.

**Acceptance Scenarios**:

1. **Given** the mapping file defines element `a1101`, **When** validated against the XSD, **Then** `strix_a1101` exists in the schema
2. **Given** the mapping specifies `type: decimal` for an element, **When** the XSD is checked, **Then** the element's type includes `monetaryItemType`
3. **Given** the mapping references an obsolete element, **When** validation runs, **Then** a warning is generated listing obsolete elements

---

### Edge Cases

- What happens when a client has no nationality set? (Should be excluded from nationality breakdown, not generate invalid country code)
- What happens when transaction value is zero or negative? (Zero values may be valid; negative values should be flagged)
- What happens when settings are missing for Controls section elements? (Should generate with default/null values or flag as incomplete)
- What happens when organization has no clients or transactions? (Should generate valid XBRL with zero counts, not empty/null)
- What happens when an element value contains special characters? (Should be properly XML-escaped)

## Requirements

### Functional Requirements

- **FR-001**: System MUST validate that every XBRL element name in generated output matches an element defined in the AMSF taxonomy XSD schema
- **FR-002**: System MUST validate that the `amsf_element_mapping.yml` configuration only references elements that exist in the taxonomy
- **FR-003**: System MUST validate that element data types match taxonomy specifications (integerItemType, monetaryItemType, stringItemType, enumerated types)
- **FR-004**: System MUST validate that all mandatory survey sections have populated elements when relevant data exists
- **FR-005**: System MUST validate that calculation results match expected values for known test data sets
- **FR-006**: System MUST validate XBRL document structure (namespaces, contexts, units, schema references)
- **FR-007**: System MUST validate dimensional contexts for country-specific data breakdowns
- **FR-008**: System MUST validate that French boolean conventions (Oui/Non) are used for enum elements where required
- **FR-009**: System MUST parse the official XSD schema to extract the authoritative list of valid elements and their types
- **FR-010**: System MUST generate clear error messages identifying exactly which elements fail validation and why
- **FR-011**: System MUST track taxonomy coverage percentage (elements mapped / total elements)
- **FR-012**: System MUST validate that monetary values include appropriate `decimals` attributes

### Key Entities

- **XBRL Taxonomy (XSD)**: The authoritative schema defining all 321 valid element names and their types
- **Element Mapping (YAML)**: Application configuration mapping internal data sources to XBRL elements
- **Submission**: The annual report being generated, containing all SubmissionValues
- **SubmissionValue**: Individual data points with element names, values, and sources
- **Generated XBRL**: The XML document output that must conform to the taxonomy

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of element names in generated XBRL files match taxonomy-defined elements (zero invalid element names)
- **SC-002**: Taxonomy coverage tracking shows what percentage of 321 elements the application supports
- **SC-003**: All calculation tests pass with exact expected values for 10+ distinct calculation scenarios
- **SC-004**: Generated XBRL files pass well-formedness validation with zero XML parsing errors
- **SC-005**: Test suite executes in under 30 seconds for typical use cases
- **SC-006**: Test failures include specific element names and expected vs actual values for easy debugging
- **SC-007**: Mapping configuration validation catches 100% of obsolete or misspelled element references

## Assumptions

- The official AMSF taxonomy XSD file (`strix_Real_Estate_AML_CFT_survey_2025.xsd`) is the authoritative source for valid element names
- Elements with `abstract="true"` in the XSD are not data elements and should not be generated in output
- The taxonomy uses instant period type (point-in-time values as of December 31)
- French language conventions apply for boolean values (Oui/Non rather than true/false)
- Country codes follow ISO 3166-1 alpha-2 standard
- Monetary values are in EUR with 2 decimal precision
