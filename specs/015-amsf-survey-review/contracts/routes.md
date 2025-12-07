# Routes Contract: AMSF Survey Review Page

**Branch**: `015-amsf-survey-review` | **Date**: 2025-12-05

## New Routes

### Survey Review (Primary)

```ruby
# config/routes.rb (addition)
resources :submissions, only: [] do
  resource :review, only: [:show], controller: "survey_reviews"
  post "review/complete", to: "survey_reviews#complete"
end
```

| Method | Path | Controller#Action | Purpose |
|--------|------|-------------------|---------|
| GET | `/submissions/:submission_id/review` | `survey_reviews#show` | Display survey review page |
| POST | `/submissions/:submission_id/review/complete` | `survey_reviews#complete` | Mark submission as completed |

### Route Details

#### GET /submissions/:submission_id/review

**Purpose**: Display single-page survey review with all AMSF elements organized by questionnaire sections.

**Parameters**:
- `submission_id` (path, required): Integer ID of the submission

**Authorization**: User must have access to the submission via Pundit policy

**Response**:
- Success: Renders `survey_reviews/show.html.erb`
- Unauthorized: Redirects to root with flash error
- Not found: 404 page

**Side Effects**:
- If submission has no calculated values, triggers `CalculationEngine.calculate!` before rendering

---

#### POST /submissions/:submission_id/review/complete

**Purpose**: Mark submission as completed after user confirmation.

**Parameters**:
- `submission_id` (path, required): Integer ID of the submission

**Authorization**: User must have access to the submission via Pundit policy

**Request**:
- Content-Type: `application/x-www-form-urlencoded` (standard form submission)
- CSRF token required

**Response**:
- Success: Redirects to submission show page with flash notice
- Unauthorized: Redirects to root with flash error
- Not found: 404 page
- Already completed: Redirects to submission show page (no error)

**Side Effects**:
- Updates `Submission.status` to "completed"
- Updates `Submission.completed_at` timestamp

## Named Routes

```ruby
# Available helpers after configuration
submission_review_path(@submission)           # => "/submissions/123/review"
complete_submission_review_path(@submission)  # => "/submissions/123/review/complete"
```

## Controller Skeleton

```ruby
# app/controllers/survey_reviews_controller.rb
class SurveyReviewsController < ApplicationController
  before_action :set_submission
  before_action :authorize_submission

  # GET /submissions/:submission_id/review
  def show
    ensure_values_calculated
    @sections = build_sections_with_elements
  end

  # POST /submissions/:submission_id/review/complete
  def complete
    if @submission.draft?
      @submission.complete!
      redirect_to @submission, notice: "Submission completed successfully."
    else
      redirect_to @submission, notice: "Submission is already completed."
    end
  end

  private

  def set_submission
    @submission = policy_scope(Submission).find(params[:submission_id])
  end

  def authorize_submission
    authorize @submission, :show?
  end

  def ensure_values_calculated
    return if @submission.submission_values.exists?
    CalculationEngine.calculate!(@submission)
  end

  def build_sections_with_elements
    manifest = Xbrl::ElementManifest.new(@submission)
    Xbrl::Survey.sections.map do |section|
      {
        id: section[:id],
        title: section[:title],
        elements: section[:elements].map { |name| manifest.find(name) }.compact
      }
    end
  end
end
```

## Pundit Policy

Uses existing `SubmissionPolicy`:

```ruby
# app/policies/submission_policy.rb (existing)
class SubmissionPolicy < ApplicationPolicy
  def show?
    record.account == user.current_account
  end
end
```

## Testing Routes

```ruby
# test/controllers/survey_reviews_controller_test.rb
class SurveyReviewsControllerTest < ActionDispatch::IntegrationTest
  test "GET /submissions/:id/review requires authentication" do
    get submission_review_path(submissions(:draft))
    assert_redirected_to new_user_session_path
  end

  test "GET /submissions/:id/review shows all sections" do
    sign_in users(:admin)
    get submission_review_path(submissions(:draft))
    assert_response :success
    assert_select "section", count: Xbrl::Survey.sections.count
  end

  test "POST /submissions/:id/review/complete marks submission completed" do
    sign_in users(:admin)
    submission = submissions(:draft)

    post complete_submission_review_path(submission)

    assert_redirected_to submission_path(submission)
    assert submission.reload.completed?
  end
end
```
