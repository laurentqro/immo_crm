# Feature Specification: AMSF Taxonomy Compliance

**Feature Branch**: `012-amsf-taxonomy-compliance`
**Created**: December 2024
**Status**: Draft
**Input**: User description: "Now that we have a comprehensive test suite validating XBRL output against the official AMSF taxonomy (323 elements), I'd like to make sure the application meets these specifications."

## Clarifications

### Session 2024-12-03

- Q: What is the scope for B/W suffix elements in this feature? → A: Deferred - Fix element names only; generate only B-suffix elements (skip W-suffix for now)

## User Scenarios & Testing

### User Story 1 - Valid Element Names in XBRL Output (Priority: P1)

As a real estate agent submitting my annual AML/CFT survey to Monaco's AMSF (Autorité Monégasque de Sécurité Financière), I need every element in my generated XBRL file to match the official taxonomy, so that my submission is accepted and not rejected for invalid element names.

**Why this priority**: The compliance test suite currently shows 21 invalid element names in generated output. Invalid element names cause immediate rejection by the AMSF submission system. This is the most critical issue blocking compliant submissions.

**Independent Test**: Can be tested by running `bin/rails test test/compliance/xbrl_taxonomy_test.rb` and verifying all element name tests pass.

**Acceptance Scenarios**:

1. **Given** the CalculationEngine populates submission values, **When** XBRL is generated, **Then** every element name in the output exists in the official AMSF taxonomy XSD (323 non-abstract elements)
2. **Given** elements like `a1301`, `a2102`, `a2103` that don't exist in the taxonomy, **When** the CalculationEngine runs, **Then** these are replaced with valid taxonomy elements (e.g., `a12002B` for PEP clients)
3. **Given** country breakdown elements currently use pattern `a1103_XX`, **When** generating nationality statistics, **Then** use proper XBRL dimensional contexts instead of underscore-suffixed element names

---

### User Story 2 - Valid Element Mapping Configuration (Priority: P1)

As a developer maintaining the XBRL generation system, I need the element mapping configuration to reference only valid taxonomy elements, so that future development doesn't introduce invalid element names.

**Why this priority**: The mapping configuration is the source of truth for element names. Tests show 11 invalid category names in `amsf_element_mapping.yml` that need restructuring to use actual taxonomy element names.

**Independent Test**: Can be tested by running `bin/rails test test/compliance/element_mapping_test.rb` and verifying all mapping tests pass.

**Acceptance Scenarios**:

1. **Given** the `config/amsf_element_mapping.yml` file, **When** each element name is validated against the taxonomy, **Then** 100% of element names exist in the official XSD
2. **Given** category placeholders like `entity_identification`, `client_statistics`, **When** the mapping is restructured, **Then** these are replaced with actual taxonomy element names (e.g., `a1101`, `a1102`, etc.)
3. **Given** a developer adds a new element to the mapping, **When** running the test suite, **Then** invalid element names are caught before deployment

---

### User Story 3 - Correct Element Types and Values (Priority: P2)

As a compliance officer, I need each XBRL element value to match the data type defined in the taxonomy (integer, monetary, enumeration), so that automated validators accept my submission.

**Why this priority**: Type mismatches cause validation failures. The taxonomy defines strict types for each of the 323 elements, and values must conform.

**Independent Test**: Can be tested by running `bin/rails test test/compliance/xbrl_type_test.rb` and verifying all type tests pass.

**Acceptance Scenarios**:

1. **Given** integer elements like `a1101` (total unique clients), **When** generated, **Then** the value is a whole number without decimals
2. **Given** monetary elements like `a2104B` (transaction value), **When** generated, **Then** the value includes a `unitRef` to EUR and a `decimals` attribute
3. **Given** enumeration elements with `Oui/Non` allowed values, **When** generated, **Then** French boolean values are used (not `true/false`)
4. **Given** element `a11001BTOLA` has allowed values `[Oui, Non]`, **When** generated, **Then** only these exact values appear

---

### User Story 4 - Dimensional Contexts for Country Breakdowns (Priority: P2)

As a real estate agent with international clients, I need nationality breakdowns to use proper XBRL dimensional contexts, so that country-specific statistics are correctly attributed in my submission.

**Why this priority**: Currently generating invalid `a1103_XX` elements. The AMSF taxonomy uses XBRL dimensions for country breakdowns, which requires properly structured dimensional contexts.

**Independent Test**: Can be tested by running `bin/rails test test/compliance/xbrl_dimension_test.rb` and verifying all dimension tests pass.

**Acceptance Scenarios**:

1. **Given** clients from France and Germany, **When** XBRL is generated, **Then** separate dimensional contexts exist with `CountryDimension` values of `FR` and `DE`
2. **Given** the taxonomy's `CountryDomain` specifies ISO 3166-1 alpha-2 codes, **When** processing nationality data, **Then** only valid 2-letter country codes are used in dimensional contexts
3. **Given** a country-specific fact needs to be reported, **When** the element is generated, **Then** it references the correct dimensional context (not an underscore-suffixed element name)

---

### User Story 5 - Complete XBRL Document Structure (Priority: P2)

As a submission system receiving XBRL files, I need generated documents to have valid structure (namespaces, contexts, units, schema references), so that automated parsers can process the submission.

**Why this priority**: Even with correct element names, structural issues prevent processing. The generator must produce well-formed XBRL 2.1 compliant documents.

**Independent Test**: Can be tested by running `bin/rails test test/compliance/xbrl_structure_test.rb` and verifying all structure tests pass.

**Acceptance Scenarios**:

1. **Given** any generated XBRL file, **When** parsed as XML, **Then** the document is well-formed with zero parsing errors
2. **Given** XBRL 2.1 specification requirements, **When** XBRL is generated, **Then** required namespaces (xbrl, link, xlink, iso4217, strix) are declared
3. **Given** facts require context references, **When** any fact element is generated, **Then** its `contextRef` points to an existing context element
4. **Given** numeric facts require unit references, **When** monetary values are generated, **Then** they reference the EUR unit; **When** count values are generated, **Then** they reference the pure unit

---

### User Story 6 - Calculation Accuracy (Priority: P2)

As an organization, I need the statistical calculations to accurately reflect my CRM data using correct taxonomy element names, so that my AMSF submission contains truthful, correctly-attributed figures.

**Why this priority**: The CalculationEngine currently uses 21 invalid element names that must be fixed while maintaining calculation accuracy.

**Independent Test**: Can be tested by running `bin/rails test test/compliance/xbrl_calculation_test.rb` and verifying all calculation tests pass.

**Acceptance Scenarios**:

1. **Given** 10 natural person clients and 5 legal entity clients, **When** calculations run with correct element names, **Then** client counts are attributed to valid taxonomy elements
2. **Given** PEP client tracking exists, **When** calculations run, **Then** PEP statistics use valid elements like `a12002B` (not the invalid `a1301`)
3. **Given** transaction value calculations exist, **When** calculating totals, **Then** amounts are attributed to valid monetary elements with B/W suffixes as appropriate

---

### Edge Cases

- What happens when a client has no nationality set? (Should be excluded from dimensional breakdown, not generate invalid country code)
- What happens when an element value contains special characters? (Should be properly XML-escaped)
- What happens when the taxonomy XSD file is missing or corrupt? (Clear error message indicating the missing file location)
- What happens when a calculated value is nil or empty? (Should not generate the element, or generate with proper nil handling per XBRL spec)
- What happens when country code doesn't match ISO 3166-1 alpha-2 format? (Should normalize or exclude from dimensional breakdown)

## Requirements

### Functional Requirements

- **FR-001**: System MUST generate XBRL elements with names that exist in the official AMSF taxonomy XSD (323 non-abstract elements)
- **FR-002**: System MUST NOT generate any of the 21 currently-invalid element names identified in test failures (`a1301`, `a2102`, `a2103`, `a2104`, `a2105`, `a2106`, `a2107`, `a2201`, `a2301`, `a2302`, `a2401`, `a1502`, and underscore-suffixed country elements)
- **FR-003**: System MUST use dimensional contexts for country-specific data breakdowns instead of underscore-suffixed element names
- **FR-004**: System MUST use correct data types as defined in taxonomy (integerItemType, monetaryItemType, enumerated Oui/Non types)
- **FR-005**: System MUST validate that the element mapping configuration only references taxonomy-valid elements
- **FR-006**: System MUST restructure the mapping configuration to use actual taxonomy element names instead of category placeholders
- **FR-007**: System MUST generate valid XBRL document structure (namespaces, contexts, units, schema references)
- **FR-008**: System MUST use French boolean conventions (`Oui`/`Non`) for enumerated boolean elements
- **FR-009**: System MUST include proper `unitRef` attributes for numeric elements (EUR for monetary, pure for counts)
- **FR-010**: System MUST include proper `contextRef` attributes for all fact elements
- **FR-011**: System MUST include `decimals` attribute for monetary values
- **FR-012**: System MUST use valid B-suffix element names where applicable; W-suffix (WITH clients) elements are deferred to a future iteration requiring Transaction.direction data model enhancement

### Key Entities

- **AMSF Taxonomy (XSD)**: The authoritative schema at `docs/strix_Real_Estate_AML_CFT_survey_2025.xsd` defining all 323 valid element names, their types, and allowed values
- **Element Mapping (YAML)**: Configuration at `config/amsf_element_mapping.yml` mapping internal data sources to XBRL elements
- **CalculationEngine**: Service that populates SubmissionValues with calculated statistics from CRM data
- **XbrlGenerator**: Service that transforms SubmissionValues into XBRL XML documents
- **SubmissionValue**: Individual data points with element names, values, and calculation sources
- **XbrlTestHelper**: Test support module that parses the taxonomy XSD and provides validation utilities

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of compliance tests pass (currently 4 failing, 3 skipped out of 57)
- **SC-002**: Zero invalid element names appear in generated XBRL output (currently 21 invalid)
- **SC-003**: Zero invalid element references in the mapping configuration (currently 11 invalid)
- **SC-004**: All element values match their taxonomy-defined types with appropriate attributes
- **SC-005**: All country breakdowns use proper dimensional contexts instead of underscore-suffixed names
- **SC-006**: Generated XBRL files pass well-formedness validation with zero parsing errors
- **SC-007**: Complete test suite execution time remains reasonable (under 30 seconds for compliance tests)

## Assumptions

- The official AMSF taxonomy XSD file (`strix_Real_Estate_AML_CFT_survey_2025.xsd`) is the authoritative source for valid element names and is already present in `docs/`
- The taxonomy has 323 non-abstract elements and 105 Tab 4 (Controls) elements as documented in `XbrlTestHelper`
- The existing compliance test suite accurately validates against the taxonomy requirements
- French language conventions apply for boolean values (`Oui`/`Non` rather than `true`/`false`)
- Country codes follow ISO 3166-1 alpha-2 standard
- Monetary values are in EUR with appropriate decimal precision
- W-suffix elements (WITH clients - agent commissions) are out of scope for this feature; only B-suffix elements (BY clients) will be generated until Transaction.direction field is added in a future iteration
