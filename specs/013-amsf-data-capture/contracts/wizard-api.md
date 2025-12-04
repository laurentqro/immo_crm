# Wizard Controller API Contract

**Branch**: `013-amsf-data-capture` | **Date**: 2025-12-04

## Overview

Extension of existing `SubmissionStepsController` to support 7-step AMSF survey submission wizard.

## Routes

```ruby
# config/routes.rb (existing resource, extend steps)
resources :submissions do
  resources :submission_steps, only: [:show, :update], param: :step do
    member do
      post :confirm
      post :lock      # NEW: Acquire edit lock
      delete :unlock  # NEW: Release edit lock
    end
  end
end
```

**Resulting endpoints:**

| Method | Path | Action | Purpose |
|--------|------|--------|---------|
| GET | `/submissions/:id/submission_steps/:step` | show | Display wizard step |
| PATCH | `/submissions/:id/submission_steps/:step` | update | Save step data, navigate |
| POST | `/submissions/:id/submission_steps/:step/confirm` | confirm | Confirm step values |
| POST | `/submissions/:id/submission_steps/:step/lock` | lock | Acquire edit lock |
| DELETE | `/submissions/:id/submission_steps/:step/unlock` | unlock | Release edit lock |

## Step Definitions

| Step | Name | FR Coverage | Data Displayed |
|------|------|-------------|----------------|
| 1 | Activity Confirmation | - | Organization activity flags from Settings |
| 2 | Client Statistics | FR-010, FR-014 | Client counts by type, nationality, risk, PEP |
| 3 | Transaction Statistics | FR-011, FR-014 | Transaction counts/values by type |
| 4 | Training & Compliance | FR-013, FR-014 | Training sessions, STR counts, staff |
| 5 | Revenue Review | FR-012, FR-014 | Management, rental, sales revenue |
| 6 | Policy Confirmation | - | aC* control elements from Settings |
| 7 | Review & Sign | FR-022, FR-023 | Summary, signatory, legal confirmation |

## Request/Response Formats

### GET /submissions/:id/submission_steps/:step

**Response (HTML):** Renders step template with pre-populated data.

**Instance Variables Set:**

```ruby
# Step 1: Activity Confirmation
@activity_settings = {
  sales: boolean,
  rentals: boolean,
  property_management: boolean
}

# Step 2: Client Statistics
@client_statistics = [
  { element: "a1101", label: "Total clients", value: 47, source: "Calculated from 47 clients" },
  { element: "a1102", label: "Natural persons", value: 35, source: "Calculated" },
  # ...
]
@previous_year_comparison = {
  "a1101" => { previous: 42, current: 47, change_pct: 11.9 },
  # ...
}

# Step 3: Transaction Statistics
@transaction_statistics = [
  { element: "a2102B", label: "Purchases", value: 5, source: "Calculated" },
  { element: "a2105B", label: "Sales", value: 3, source: "Calculated" },
  { element: "a2108B", label: "Rentals", value: 12, source: "Calculated" },
  # ...
]

# Step 4: Training & Compliance
@training_statistics = [
  { element: "a3201", label: "Training conducted?", value: "Oui", source: "From 3 sessions" },
  { element: "a3202", label: "Staff trained", value: 8, source: "Calculated" },
  # ...
]
@str_statistics = [
  { element: "a3102", label: "STRs filed", value: 1, source: "From str_reports" },
]

# Step 5: Revenue Review
@revenue_statistics = [
  { element: "a3804", label: "Management revenue", value: 125000, source: "From 15 properties" },
  { element: "a3803", label: "Rental revenue", value: 45000, source: "From 12 rentals" },
  { element: "a3802", label: "Sales revenue", value: 80000, source: "From 3 sales" },
  { element: "a381", label: "Total revenue", value: 250000, source: "Calculated" },
]

# Step 6: Policy Confirmation
@policy_values = [
  { element: "aC1101Z", label: "Has internal procedures?", value: "Oui", source: "From Settings" },
  # ... 105 aC* elements
]

# Step 7: Review & Sign
@submission = Submission instance with all values
@validation_warnings = [] # Missing/incomplete fields
@signatory_name = string or nil
@signatory_title = string or nil
```

### PATCH /submissions/:id/submission_steps/:step

**Request Body (Step 2-5 - Value Override):**

```ruby
{
  submission: {
    submission_values_attributes: [
      { id: 123, value: "48", override_reason: "Corrected count per accountant review" }
    ]
  },
  commit: "continue" | "back" | "save"
}
```

**Request Body (Step 7 - Signatory):**

```ruby
{
  submission: {
    signatory_name: "Jean Dupont",
    signatory_title: "Compliance Officer"
  },
  legal_confirmation: "1",  # checkbox checked
  commit: "generate"
}
```

**Response:**
- `commit: "continue"` → Redirect to next step
- `commit: "back"` → Redirect to previous step
- `commit: "save"` → Redirect to same step with notice
- `commit: "generate"` → Generate XBRL, lock submission, redirect to download

### POST /submissions/:id/submission_steps/:step/confirm

**Request Body:**
```ruby
{ step_values: "all" }
```

**Response:**
- Confirms all values for current step (sets `confirmed_at`)
- Redirects to same step with notice

### POST /submissions/:id/submission_steps/:step/lock

**Request Body:** (none)

**Response (Success - 200):**
```json
{
  "locked": true,
  "locked_by": "current_user@example.com",
  "locked_at": "2025-12-04T10:30:00Z"
}
```

**Response (Conflict - 409):**
```json
{
  "locked": true,
  "locked_by": "other_user@example.com",
  "locked_at": "2025-12-04T10:25:00Z",
  "message": "Submission is being edited by other_user@example.com"
}
```

### DELETE /submissions/:id/submission_steps/:step/unlock

**Request Body:** (none)

**Response (Success - 200):**
```json
{
  "locked": false
}
```

## Authorization (Pundit)

```ruby
# app/policies/submission_policy.rb

def show?
  # Any organization member can view
  user_is_organization_member?
end

def update?
  # Any member can edit draft submissions
  user_is_organization_member? && record.editable?
end

def confirm?
  update?
end

def lock?
  update?
end

def unlock?
  # Only lock owner or admin can unlock
  record.locked_by_user_id == user.id || user_is_admin?
end

def generate?
  # Only compliance officer or admin can generate XBRL
  (user_is_compliance_officer? || user_is_admin?) && record.editable?
end

def reopen?
  # Only compliance officer or admin can reopen after generation
  (user_is_compliance_officer? || user_is_admin?) && record.generated_at.present?
end
```

## State Transitions

```
                    ┌─────────────┐
                    │   draft     │ ←─── create / reopen
                    └─────────────┘
                          │
                    edit via wizard
                          │
                          ▼
                    ┌─────────────┐
                    │  in_review  │
                    └─────────────┘
                          │
                    validate_submission!
                          │
                          ▼
                    ┌─────────────┐
                    │  validated  │
                    └─────────────┘
                          │
                    generate XBRL (step 7)
                          │
                          ▼
                    ┌─────────────┐
                    │  generated  │ ←─── locked, generated_at set
                    └─────────────┘
                          │
                    complete! (download)
                          │
                          ▼
                    ┌─────────────┐
                    │  completed  │
                    └─────────────┘
```

## Validation Warnings

Validation is non-blocking during wizard navigation (FR-034) but blocks XBRL generation (FR-035).

**Warning Structure:**
```ruby
@validation_warnings = [
  {
    element: "a13501B",
    message: "Source of funds not verified for 3 high-risk clients",
    severity: "warning",
    step: 2
  },
  {
    element: "a3201",
    message: "No training records found for current year",
    severity: "warning",
    step: 4
  }
]
```

## Year-over-Year Comparison

Displayed on steps 2-5 when previous year submission exists.

**Comparison Data Structure:**
```ruby
{
  element_name: {
    previous: previous_value,
    current: current_value,
    change_pct: percentage_change,
    significant: boolean  # true if |change_pct| > 25%
  }
}
```

**Highlighting Rule (FR-019):**
- Changes exceeding 25% are visually highlighted
- First submission shows "First submission" indicator
