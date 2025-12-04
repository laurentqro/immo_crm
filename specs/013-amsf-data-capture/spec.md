# Feature Specification: AMSF Survey Data Capture

**Feature Branch**: `013-amsf-data-capture`
**Created**: 2025-12-04
**Status**: Draft
**Input**: Design document `docs/plans/2025-12-04-amsf-data-capture-design.md`

## Overview

Minimize user effort at AMSF annual survey submission time by capturing all compliance data when it's "warm" during normal CRM use. Users review pre-calculated values and submit with near-zero manual data entry.

### Business Context

The AMSF (Autorité Monégasque de Sécurité Financière) requires Monaco real estate agencies to submit an annual AML/CFT survey with 323 data elements. Currently, agents must manually compile this data at submission time, which is error-prone and time-consuming.

**Monaco Market Reality**: Property management (gestion locative) is the primary revenue source for Monaco agencies due to extremely high property values. Most agents make only a handful of sales per year. Property management provides recurring revenue that covers fixed costs.

## User Scenarios & Testing

### User Story 1 - Submit Annual Survey with Pre-Calculated Data (Priority: P1)

An agency compliance officer needs to submit the annual AMSF survey. They open the submission wizard, review pre-calculated statistics from CRM data, confirm the values are accurate, and generate the XBRL file for submission.

**Why this priority**: This is the core value proposition - reducing submission effort from hours of manual data compilation to minutes of review.

**Independent Test**: Can be tested by creating a submission, walking through all wizard steps with pre-populated data, and generating a valid XBRL file.

**Acceptance Scenarios**:

1. **Given** an agency has complete CRM data for the year, **When** they start a new AMSF submission, **Then** all statistics are pre-calculated and displayed for review
2. **Given** a user is in the submission wizard, **When** they navigate through all steps, **Then** each step shows values with their calculation source (e.g., "Calculated from 47 clients")
3. **Given** a user completes all review steps, **When** they sign and submit, **Then** the system generates a valid XBRL file containing all 323 elements

---

### User Story 2 - Capture Compliance Data During Client Onboarding (Priority: P2)

When an agent creates or updates a client, they capture compliance-relevant details (due diligence level, source of funds verification, professional category) as part of the normal workflow.

**Why this priority**: Client data is the foundation of most survey statistics. Capturing it at onboarding ensures accuracy and completeness.

**Independent Test**: Can be tested by creating a client with all compliance fields, then verifying the data appears in survey statistics.

**Acceptance Scenarios**:

1. **Given** an agent is creating a new client, **When** they complete the client form, **Then** they can specify due diligence level (Standard/Simplified/Reinforced)
2. **Given** a client relationship ends, **When** the agent marks the client as inactive, **Then** they can record the termination reason
3. **Given** a client is rejected, **When** the agent records the rejection, **Then** the rejection date and reason are captured for survey statistics

---

### User Story 3 - Record Property Management Contracts (Priority: P2)

An agent records ongoing property management contracts (gestion locative) including landlord client, property details, tenant information, and fee structure.

**Why this priority**: Property management is the primary revenue source for Monaco agencies and directly impacts multiple survey elements.

**Independent Test**: Can be tested by creating a managed property record and verifying it appears in revenue and tenant statistics.

**Acceptance Scenarios**:

1. **Given** an agency takes on property management, **When** the agent creates a managed property record, **Then** they can specify landlord, property address, monthly rent, and management fee
2. **Given** a managed property has a tenant, **When** the agent records tenant details, **Then** they can capture tenant type (natural person/legal entity), country, and PEP status
3. **Given** a management contract ends, **When** the agent closes the property record, **Then** the end date is recorded and the property is excluded from active statistics

---

### User Story 4 - Record Staff Training Sessions (Priority: P3)

A compliance officer records AML/CFT training sessions including date, topic, provider, staff count, and duration.

**Why this priority**: Training data is required for the survey but typically occurs infrequently (few times per year).

**Independent Test**: Can be tested by creating training records and verifying counts appear in survey statistics.

**Acceptance Scenarios**:

1. **Given** the agency conducts AML training, **When** the compliance officer records the session, **Then** they can specify date, type (initial/refresher/specialized), topic, and provider
2. **Given** training records exist for the year, **When** viewing the submission wizard, **Then** training statistics are automatically calculated

---

### User Story 5 - Override Calculated Values (Priority: P3)

A user identifies that a calculated value is incorrect due to data quality issues and needs to override it with the correct value.

**Why this priority**: Edge cases exist where calculated values may be incorrect, requiring manual correction.

**Independent Test**: Can be tested by overriding a value and verifying it persists through XBRL generation.

**Acceptance Scenarios**:

1. **Given** a user is reviewing calculated statistics, **When** they identify an incorrect value, **Then** they can override it with a corrected value and provide a reason
2. **Given** a value has been overridden, **When** viewing the value, **Then** it displays an indicator showing it was manually adjusted
3. **Given** a value has been overridden, **When** the user decides the original was correct, **Then** they can revert to the calculated value

---

### User Story 6 - Compare Year-over-Year Statistics (Priority: P3)

A user reviewing survey statistics can see how values compare to the previous year to identify anomalies.

**Why this priority**: Year-over-year comparison helps users spot data entry errors or unusual changes that warrant investigation.

**Independent Test**: Can be tested by creating submissions for two consecutive years and verifying comparison displays correctly.

**Acceptance Scenarios**:

1. **Given** a previous year's submission exists, **When** viewing current year statistics, **Then** previous year values and percentage changes are displayed
2. **Given** a significant change from previous year (>25%), **When** viewing the statistic, **Then** it is visually highlighted for attention
3. **Given** no previous submission exists, **When** viewing statistics, **Then** the system handles this gracefully with "First submission" indication

---

### Edge Cases

- What happens when a property management contract spans multiple years? System calculates partial-year revenue based on months active within the reporting year.
- How does the system handle clients with incomplete compliance data? System proceeds with available data and flags missing fields for user attention during wizard review.
- What happens if required compliance fields are missing when generating XBRL? System validates completeness before allowing XBRL generation and lists missing required fields.
- How are zero-value statistics handled? System includes zero values in XBRL output; display shows "0" rather than omitting the statistic.
- What happens if the user abandons a submission partway through? Progress is auto-saved; user can resume from their last completed step.

## Requirements

### Functional Requirements

**Data Capture Requirements**:
- **FR-001**: System MUST allow recording due diligence level (Standard/Simplified/Reinforced) for each client
- **FR-002**: System MUST allow recording professional category for clients (Legal/Accountant/Notary/Real Estate/Financial/Other/None)
- **FR-003**: System MUST allow recording client rejection with timestamp and reason
- **FR-004**: System MUST allow recording source of funds and source of wealth verification status for clients
- **FR-005**: System MUST allow recording property management contracts with landlord, property details, rent, and fees
- **FR-006**: System MUST allow recording tenant information including type, country, and PEP status
- **FR-007**: System MUST allow recording training sessions with date, type, topic, provider, staff count, and duration
- **FR-008**: System MUST allow recording transaction property type (Residential/Commercial/Land/Mixed)
- **FR-009**: System MUST allow recording counterparty PEP status and country for transactions

**Calculation Requirements**:
- **FR-010**: System MUST automatically calculate client statistics from CRM data (counts by type, nationality, risk level, PEP status)
- **FR-011**: System MUST automatically calculate transaction statistics (counts and values by type)
- **FR-012**: System MUST automatically calculate property management revenue from fee structures
- **FR-013**: System MUST automatically calculate training statistics (session counts, staff trained, hours)
- **FR-014**: System MUST include calculation source reference for each computed value

**Submission Wizard Requirements**:
- **FR-015**: System MUST provide a step-by-step wizard for AMSF survey submission
- **FR-016**: System MUST pre-populate all calculable values before user review
- **FR-017**: System MUST display calculation source for each value (e.g., "Calculated from X records")
- **FR-018**: System MUST allow users to override calculated values with documented reason
- **FR-019**: System MUST display year-over-year comparison when previous submission exists
- **FR-020**: System MUST persist wizard progress for resumption
- **FR-021**: System MUST generate valid XBRL file containing all 323 required elements
- **FR-022**: System MUST require signatory name and title before final submission
- **FR-023**: System MUST require legal confirmation checkbox before generating XBRL
- **FR-024**: System MUST lock submission for editing after XBRL generation
- **FR-025**: System MUST allow authorized users to reopen a generated submission for edits

**Data Integrity Requirements**:
- **FR-026**: System MUST validate country codes against ISO 3166-1 alpha-2 standard
- **FR-027**: System MUST preserve manually entered values when recalculating statistics
- **FR-028**: System MUST track override audit trail (who, when, reason)
- **FR-029**: System MUST lock submission for single-user editing (prevent concurrent edits)
- **FR-032**: System MUST enforce one submission per organization per year (creating new overwrites previous draft)
- **FR-033**: System MUST display validation warnings for incomplete data throughout wizard navigation
- **FR-034**: System MUST allow wizard progression despite incomplete data (non-blocking warnings)
- **FR-035**: System MUST block XBRL generation until all required elements have valid values

**Authorization Requirements**:
- **FR-030**: System MUST restrict final AMSF survey submission to users with compliance officer or admin roles
- **FR-031**: System MUST allow any organization user to view and prepare submission data

### Key Entities

- **Client**: Individual or organization with compliance attributes (due diligence level, professional category, verification status, rejection status)
- **Transaction**: Property sale/purchase/rental with compliance attributes (property type, counterparty PEP status, counterparty country)
- **ManagedProperty**: Ongoing property management contract linking landlord client to property with tenant details and fee structure
- **Training**: Staff training session record with metadata (type, topic, provider, participants)
- **Submission**: Annual AMSF survey submission containing all 323 element values. Lifecycle states: Draft (in-progress) → Generated (locked, XBRL created) → Reopened (unlocked for edits) → Generated (re-locked)
- **SubmissionValue**: Individual XBRL element value within a submission (source, override status)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can complete the entire AMSF submission wizard in under 15 minutes (assuming complete CRM data)
- **SC-002**: At least 95% of survey statistics are pre-calculated without manual entry
- **SC-003**: All 323 XBRL elements have a defined data source (calculated, settings, or manual)
- **SC-004**: Users can compare current values to previous year and identify changes exceeding 25%
- **SC-005**: Generated XBRL files are accepted by AMSF validation without errors
- **SC-006**: Wizard progress persists across sessions allowing users to resume incomplete submissions
- **SC-007**: All manual overrides are tracked with user, timestamp, and reason

## Clarifications

### Session 2025-12-04

- Q: Who can submit the annual AMSF survey? → A: Only compliance officer or admin roles can submit
- Q: What happens to a submission after XBRL is generated? → A: Locked after generation but can be reopened for edits
- Q: Can multiple users work on the same submission simultaneously? → A: Single user at a time (submission locked while being edited)
- Q: Can an organization have multiple submissions for the same year? → A: One submission per year, new submission overwrites previous draft
- Q: When should the system validate data completeness? → A: Validate continuously with warnings, block only at generation

## Assumptions

- Agencies already have client and transaction data in the CRM for the reporting year
- The AMSF XBRL taxonomy (2025 version) is stable and won't change during implementation
- Property management fees are either percentage-based or fixed monthly amounts
- Training sessions are recorded at organization level, not per-individual staff member
- The survey is submitted once per year; amendments follow a separate process
