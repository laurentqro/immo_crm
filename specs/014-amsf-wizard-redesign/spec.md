# Feature Specification: AMSF Wizard Redesign

**Feature Branch**: `014-amsf-wizard-redesign`
**Created**: 2025-12-05
**Status**: Draft
**Input**: Replace 7-step submission wizard with 5-tab AMSF questionnaire structure

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Navigate Wizard Using AMSF Tab Structure (Priority: P1)

As a compliance officer preparing an annual AMSF submission, I want the wizard to mirror the official AMSF questionnaire's 5-tab structure so that I can easily cross-reference the official instructions PDF while reviewing pre-filled data.

**Why this priority**: This is the core structural change - without tab-based navigation matching AMSF's structure, users cannot benefit from the familiar mental model when referencing official documentation.

**Independent Test**: Can be fully tested by navigating between all 5 tabs (Customer Risk, Products & Services, Distribution Risk, Controls, Signatories) and verifying each displays the correct AMSF section groupings.

**Acceptance Scenarios**:

1. **Given** a user is viewing a submission wizard, **When** they view the navigation, **Then** they see 5 tabs labeled: "1. Customer Risk", "2. Products & Services", "3. Distribution Risk", "4. Controls", "5. Signatories"
2. **Given** a user clicks on any tab, **When** the tab loads, **Then** they see subsections matching the AMSF questionnaire numbering (e.g., Tab 1 shows sections 1.1, 1.2, 1.3, etc.)
3. **Given** a user is on any tab, **When** they click a different tab, **Then** they navigate directly to that tab without being forced through sequential steps

---

### User Story 2 - Focus on Items Requiring Review (Priority: P1)

As a compliance officer reviewing hundreds of pre-filled values, I want the interface to surface only the items that need my attention so that I can complete my review efficiently without scanning every field.

**Why this priority**: Equally critical as tab navigation - with 300+ fields, users would be overwhelmed without progressive disclosure that highlights exceptions.

**Independent Test**: Can be fully tested by viewing a submission with some flagged issues and verifying that only sections with issues auto-expand, while issue-free sections remain collapsed.

**Acceptance Scenarios**:

1. **Given** a tab has sections with no issues, **When** the user views the tab, **Then** those sections are collapsed showing only a summary (section name, completion count, green checkmark)
2. **Given** a section has items flagged for review (significant YoY change, validation warning), **When** the user views the tab, **Then** that section auto-expands with the flagged items highlighted in amber
3. **Given** a user wants to review all fields comprehensively, **When** they click "Full Review" mode, **Then** all sections expand to show all fields

---

### User Story 3 - View Tab and Section Completion Status (Priority: P2)

As a compliance officer, I want to see completion percentages for each tab and section so that I know my progress through the submission at a glance.

**Why this priority**: Provides essential feedback on progress but doesn't block core review functionality.

**Independent Test**: Can be fully tested by viewing tab badges showing issue counts and completion percentages, and section headers showing completed/total field counts.

**Acceptance Scenarios**:

1. **Given** a tab has some completed fields and some issues, **When** the user views the tab navigation, **Then** they see a badge indicating the number of items needing review
2. **Given** a tab has all fields complete with no issues, **When** the user views the tab navigation, **Then** they see a green checkmark
3. **Given** the user opens a tab, **When** they view the progress bar, **Then** they see completion percentage and count of items needing review

---

### User Story 4 - Override Pre-filled Values with Audit Trail (Priority: P2)

As a compliance officer, I want to override any pre-filled calculated value with a reason so that I can correct data while maintaining an audit trail for regulators.

**Why this priority**: Critical for compliance but builds on top of the display functionality.

**Independent Test**: Can be fully tested by overriding a calculated value, saving, and verifying the override reason and user are recorded.

**Acceptance Scenarios**:

1. **Given** a user views a calculated field, **When** they want to change the value, **Then** they can enter an override value and must provide a reason (minimum 10 characters)
2. **Given** a user has overridden a value, **When** they view that field later, **Then** they see an "Overridden" badge with the override reason and user who made the change
3. **Given** an administrator reviews audit logs, **When** they look at overrides, **Then** they see the original value, new value, reason, user, and timestamp

---

### User Story 5 - Complete Submission with Signatory Declaration (Priority: P3)

As a compliance officer, I want to complete the submission on the final tab with my name and attestation so that I take responsibility for the accuracy of the submitted data.

**Why this priority**: Required for final submission but depends on all other stories being complete.

**Independent Test**: Can be fully tested by navigating to Signatories tab, entering signatory details, checking attestation, and completing the submission.

**Acceptance Scenarios**:

1. **Given** a user is on the Signatories tab, **When** they view the page, **Then** they see a summary of all tabs' completion status
2. **Given** a user enters signatory name and title, **When** they check the attestation checkbox and click "Complete Submission", **Then** the submission is marked complete
3. **Given** a user has not resolved all flagged issues, **When** they attempt to complete, **Then** they see a warning (but are not blocked if they confirm)

---

### User Story 6 - Backward Compatibility for Existing Links (Priority: P3)

As a system administrator, I want existing bookmarks and links using numeric step URLs to redirect to the new tab-based URLs so that users don't encounter broken links.

**Why this priority**: Nice-to-have for smooth transition but not blocking core functionality.

**Independent Test**: Can be fully tested by accessing old URLs like `/submissions/1/submission_steps/1` and verifying redirect to `/submissions/1/submission_steps/customer_risk`.

**Acceptance Scenarios**:

1. **Given** a user has bookmarked `/submissions/123/submission_steps/1`, **When** they access this URL, **Then** they are redirected to `/submissions/123/submission_steps/customer_risk`
2. **Given** any legacy step number 1-7 is accessed, **When** the system handles the request, **Then** it redirects to the appropriate tab with a 301 (permanent redirect) status

---

### Edge Cases

- What happens when a user navigates to an invalid tab name? System returns 404 Not Found
- How does the system handle concurrent editing? Existing lock mechanism prevents conflicts with banner notifications
- What happens if YoY comparison data is unavailable (first year of use)? No YoY badges shown, fields display normally
- How does the system handle sections with no elements mapped? Empty sections are hidden from the UI

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display 5 tabs in the submission wizard matching AMSF questionnaire structure: Customer Risk, Products & Services, Distribution Risk, Controls, Signatories
- **FR-002**: System MUST allow non-sequential navigation between tabs (users can jump to any tab)
- **FR-003**: System MUST organize elements within each tab into numbered subsections matching AMSF questionnaire (1.1, 1.2, 2.1, etc.)
- **FR-004**: System MUST collapse sections by default unless they contain items flagged for review
- **FR-005**: System MUST auto-expand sections containing items with significant year-over-year changes or validation warnings
- **FR-006**: System MUST display completion percentage per tab in the navigation
- **FR-007**: System MUST display issue count badges on tabs that have items requiring review
- **FR-008**: System MUST provide a "Focus Mode" (default) showing only flagged items and a "Full Review" mode showing all items
- **FR-009**: System MUST highlight flagged fields with amber background and "Review" badge
- **FR-010**: System MUST allow users to override calculated values with a mandatory reason (minimum 10 characters)
- **FR-011**: System MUST record override audit trail including original value, new value, reason, user, and timestamp
- **FR-012**: System MUST display signatory name, title, and attestation checkbox on the Signatories tab
- **FR-013**: System MUST show a submission summary on the Signatories tab with completion status of all tabs
- **FR-014**: System MUST redirect legacy numeric step URLs (1-7) to corresponding tab URLs with 301 status
- **FR-015**: System MUST preserve existing pessimistic locking behavior for concurrent edit protection
- **FR-016**: System MUST map all 323 XBRL taxonomy elements to their appropriate AMSF tabs and sections

### Key Entities

- **Tab**: Represents one of 5 AMSF questionnaire tabs with id, name, number, description, and sections
- **Section**: A numbered subsection within a tab (e.g., "1.2 Client Summary") containing element references
- **Element**: An XBRL taxonomy element mapped to a specific section, with value, source, and review status
- **SubmissionValue**: Stores element values for a submission with override capability and metadata for review flags

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can navigate directly to any tab in under 2 seconds (no forced sequential progression)
- **SC-002**: Users reviewing a submission with 5 flagged items can identify all issues within 30 seconds (vs. scanning 300+ fields)
- **SC-003**: 100% of AMSF questionnaire sections are represented in the correct tab with matching numbering
- **SC-004**: All legacy step URLs (1-7) redirect correctly to their corresponding tabs
- **SC-005**: Users can complete a submission review with zero flagged issues in under 10 minutes
- **SC-006**: Compliance officers can cross-reference the wizard with the AMSF PDF instructions without mental translation

## Assumptions

- The existing XBRL taxonomy and element mapping accurately reflects the AMSF questionnaire structure
- Users are familiar with the AMSF questionnaire format from prior years of manual completion
- The YearOverYearComparator service is already functioning for detecting significant changes
- Existing CalculationEngine correctly populates submission values from CRM data
- Existing lock/unlock mechanism is sufficient for concurrent editing protection
