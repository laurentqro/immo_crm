# Feature Specification: AMSF Survey Review Page

**Feature Branch**: `015-amsf-survey-review`
**Created**: 2025-12-05
**Status**: Draft
**Input**: User description: "Replace the 7-step AMSF submission wizard with a single-page survey review displaying all elements with search and filter capabilities"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Review All Survey Elements (Priority: P1)

As a compliance officer, I want to view all AMSF survey elements on a single scrollable page organized by official questionnaire sections so that I can efficiently review the entire submission before completing it.

**Why this priority**: This is the core functionality replacing the existing 7-step wizard. Without this, users cannot review submissions at all.

**Independent Test**: Can be tested by navigating to a submission's review page and verifying all elements are displayed organized by AMSF questionnaire sections with their calculated values.

**Acceptance Scenarios**:

1. **Given** a submission with calculated values exists, **When** I navigate to the review page, **Then** I see all survey elements organized by AMSF sections (1.1, 1.2, etc.)
2. **Given** I am on the review page, **When** I scroll through the page, **Then** I can see all 300+ elements without clicking through multiple steps
3. **Given** a submission exists, **When** I access the review page for the first time and values haven't been calculated, **Then** the system automatically calculates and displays all values

---

### User Story 2 - Search Survey Elements (Priority: P1)

As a compliance officer, I want to search for specific survey elements by name or label so that I can quickly locate any element without scrolling through 300+ items.

**Why this priority**: With 300+ elements, search is essential for usability. Without it, finding a specific element would be impractical.

**Independent Test**: Can be tested by typing a search term and verifying that only matching elements are displayed, with non-matching elements hidden.

**Acceptance Scenarios**:

1. **Given** I am on the review page, **When** I type "PEP" in the search box, **Then** only elements containing "PEP" in their name or label are visible
2. **Given** I have entered a search term, **When** results are filtered, **Then** I see a count of visible elements (e.g., "15 elements")
3. **Given** elements are filtered by search, **When** section headers have no visible elements, **Then** those section headers are also hidden
4. **Given** I have a search filter active, **When** I clear the search box, **Then** all elements become visible again

---

### User Story 3 - Filter Elements Needing Review (Priority: P2)

As a compliance officer, I want to filter to show only elements flagged for review so that I can focus on items that need attention before completing the submission.

**Why this priority**: Provides efficiency for users who only need to address flagged items rather than reviewing everything.

**Independent Test**: Can be tested by enabling the "needs review" filter and verifying only flagged elements are displayed.

**Acceptance Scenarios**:

1. **Given** some elements are flagged for review, **When** I enable the "Needs review only" filter, **Then** only flagged elements are visible
2. **Given** an element is flagged for review, **When** I view it on the page, **Then** it is visually highlighted (distinct background color and badge)
3. **Given** a section contains flagged elements, **When** viewing the section header, **Then** the section header shows a "Review" badge

---

### User Story 4 - Complete Submission (Priority: P1)

As a compliance officer, I want to complete a submission from the review page so that I can finalize and submit the AMSF survey after reviewing all values.

**Why this priority**: This is the final action users need to take after reviewing. Without completion, the review page has no practical purpose.

**Independent Test**: Can be tested by clicking the "Complete Submission" button and verifying the submission status changes to completed.

**Acceptance Scenarios**:

1. **Given** I am on the review page for a draft submission, **When** I click "Complete Submission", **Then** I am asked to confirm the action
2. **Given** I confirm completion, **When** the action succeeds, **Then** the submission is marked as completed and I am redirected to the submission detail page
3. **Given** the submission is already completed, **When** I view the review page, **Then** the complete button is not available and I see the current status

---

### Edge Cases

- What happens when a user accesses a submission they don't have permission to view? (Access denied)
- What happens when search returns no results? (Show "0 elements" count, all sections hidden)
- What happens when no elements are flagged for review but user enables the filter? (Show empty state with "0 elements" count)
- What happens if a user is not authenticated? (Redirect to login page)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display all AMSF survey elements on a single scrollable page
- **FR-002**: System MUST organize elements by official AMSF questionnaire sections (1.1, 1.2, 2.1, etc.)
- **FR-003**: System MUST show each element's short label, element code, current value, and source
- **FR-004**: System MUST provide a text search input that filters elements by name and label
- **FR-005**: System MUST update the visible element count as filters are applied
- **FR-006**: System MUST hide section headers when all their elements are filtered out
- **FR-007**: System MUST provide a "Needs review only" toggle filter
- **FR-008**: System MUST visually highlight elements flagged for review with distinct styling
- **FR-009**: System MUST display a "Review" badge on section headers containing flagged elements
- **FR-010**: System MUST provide a "Complete Submission" button for draft submissions
- **FR-011**: System MUST require confirmation before completing a submission
- **FR-012**: System MUST redirect to the submission detail page after successful completion
- **FR-013**: System MUST automatically calculate submission values if none exist when accessing the review page
- **FR-014**: System MUST enforce authorization - users can only view submissions they have access to
- **FR-015**: System MUST validate that the survey structure references only valid taxonomy elements at startup

### Key Entities

- **Submission**: Annual AMSF compliance submission for an organization, contains calculated and manual values
- **SubmissionValue**: Individual survey element value with metadata including source, override status, and review flags
- **Survey Section**: Logical grouping of elements matching the official AMSF questionnaire structure
- **Survey Element**: Individual data point in the questionnaire, defined by the XBRL taxonomy

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can locate any specific element within 10 seconds using search
- **SC-002**: Users can review all submission values without navigating between multiple pages
- **SC-003**: Users can identify elements needing review within 5 seconds using the filter
- **SC-004**: Users can complete a submission in fewer steps than the previous 7-step wizard
- **SC-005**: Page displays all 300+ elements with search/filter responding instantly (no perceptible delay)
- **SC-006**: 100% of survey elements are validated against the taxonomy at application startup

## Assumptions

- The AMSF questionnaire structure (sections and element assignments) is stable and changes infrequently
- Users prefer to see all elements at once rather than navigating through multiple wizard steps
- The "needs review" flag is set via metadata on SubmissionValue records
- Client-side filtering is appropriate given all ~300 elements are already loaded on the page
- Read-only display is sufficient for MVP; inline editing will be added in a future iteration
- Lock/unlock functionality for concurrent editing is not needed for MVP
