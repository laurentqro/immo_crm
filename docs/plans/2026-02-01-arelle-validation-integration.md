# Arelle Validation Integration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate Arelle XBRL validation into immo_crm so users get validation feedback before completing submissions.

**Architecture:** Create an ArelleClient HTTP client to call the arelle_api service. Add `validate_with_arelle` method to Survey that returns structured validation results. Wire into SubmissionsController to block completion on validation errors and show errors in the review UI.

**Tech Stack:** Ruby on Rails 8.1, ApplicationClient pattern, Minitest, WebMock for stubbing

---

### Task 1: Create ArelleClient HTTP Client

**Files:**
- Create: `app/clients/arelle_client.rb`
- Test: `test/clients/arelle_client_test.rb`

**Step 1: Write the failing test**

Create `test/clients/arelle_client_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

class ArelleClientTest < ActiveSupport::TestCase
  setup do
    @client = ArelleClient.new
  end

  test "validate returns ValidationResult on success" do
    stub_request(:post, "http://localhost:8000/validate")
      .with(body: "<xml/>", headers: {"Content-Type" => "application/xml"})
      .to_return(
        status: 200,
        body: {valid: true, summary: {errors: 0, warnings: 0, info: 1}, messages: []}.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    result = @client.validate("<xml/>")

    assert result.valid
    assert_equal 0, result.summary[:errors]
    assert_empty result.errors
  end

  test "validate returns errors from response" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          summary: {errors: 1, warnings: 0, info: 0},
          messages: [{severity: "error", code: "test", message: "Test error"}]
        }.to_json,
        headers: {"Content-Type" => "application/json"}
      )

    result = @client.validate("<xml/>")

    assert_not result.valid
    assert_equal 1, result.errors.length
    assert_equal "Test error", result.error_messages.first
  end

  test "validate raises ConnectionError when service unavailable" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_raise(Errno::ECONNREFUSED)

    assert_raises(ArelleClient::ConnectionError) do
      @client.validate("<xml/>")
    end
  end

  test "available? returns true when service responds" do
    stub_request(:get, "http://localhost:8000/docs")
      .to_return(status: 200)

    assert @client.available?
  end

  test "available? returns false when service unavailable" do
    stub_request(:get, "http://localhost:8000/docs")
      .to_raise(Errno::ECONNREFUSED)

    assert_not @client.available?
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/clients/arelle_client_test.rb -v`
Expected: FAIL with "uninitialized constant ArelleClient"

**Step 3: Write minimal implementation**

Create `app/clients/arelle_client.rb`:

```ruby
# frozen_string_literal: true

# HTTP client for the Arelle XBRL validation API.
#
# Validates XBRL documents against the taxonomy schema and XULE rules.
# Returns structured validation results with errors, warnings, and info messages.
#
# Usage:
#   client = ArelleClient.new
#   result = client.validate(xml_content)
#   result.valid?     # => true/false
#   result.errors     # => array of error messages
#
class ArelleClient < ApplicationClient
  BASE_URI = ENV.fetch("ARELLE_API_URL", "http://localhost:8000")

  ValidationResult = Data.define(:valid, :summary, :messages) do
    def errors
      messages.select { |m| m[:severity] == "error" }
    end

    def warnings
      messages.select { |m| m[:severity] == "warning" }
    end

    def error_messages
      errors.map { |m| m[:message] }
    end
  end

  class ConnectionError < Error; end

  def content_type = "application/xml"

  def authorization_header = {}

  # Validate XBRL content against Arelle.
  #
  # @param xml_content [String] the XBRL XML to validate
  # @return [ValidationResult] structured validation result
  # @raise [ConnectionError] if cannot connect to Arelle API
  def validate(xml_content)
    response = post("/validate", body: xml_content)
    parse_validation_response(response)
  rescue *NET_HTTP_ERRORS => e
    raise ConnectionError, "Cannot connect to Arelle API at #{base_uri}: #{e.message}"
  end

  # Check if Arelle API is available.
  #
  # @return [Boolean] true if API responds
  def available?
    get("/docs")
    true
  rescue *NET_HTTP_ERRORS, Error
    false
  end

  private

  def parse_validation_response(response)
    data = JSON.parse(response.body, symbolize_names: true)

    ValidationResult.new(
      valid: data[:valid],
      summary: data[:summary],
      messages: data[:messages]
    )
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/clients/arelle_client_test.rb -v`
Expected: PASS (5 tests, 0 failures)

**Step 5: Commit**

```bash
git add app/clients/arelle_client.rb test/clients/arelle_client_test.rb
git commit -m "feat: add ArelleClient for XBRL validation API

- Create ArelleClient extending ApplicationClient
- Return structured ValidationResult with errors/warnings
- Handle connection errors gracefully
- Add available? health check method"
```

---

### Task 2: Add validate_with_arelle to Survey

**Files:**
- Modify: `app/models/survey.rb`
- Test: `test/models/survey_test.rb`

**Step 1: Write the failing test**

Add to `test/models/survey_test.rb`:

```ruby
# === Arelle Validation Tests ===

test "validate_with_arelle returns validation result when enabled" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_return(
      status: 200,
      body: {valid: true, summary: {errors: 0}, messages: []}.to_json,
      headers: {"Content-Type" => "application/json"}
    )

  with_arelle_enabled do
    result = @survey.validate_with_arelle

    assert_instance_of ArelleClient::ValidationResult, result
    assert result.valid
  end
end

test "validate_with_arelle returns nil when disabled" do
  with_arelle_disabled do
    result = @survey.validate_with_arelle

    assert_nil result
  end
end

test "validate_with_arelle returns error result on validation failure" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_return(
      status: 200,
      body: {
        valid: false,
        summary: {errors: 1},
        messages: [{severity: "error", code: "test", message: "Missing field"}]
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    )

  with_arelle_enabled do
    result = @survey.validate_with_arelle

    assert_not result.valid
    assert_includes result.error_messages, "Missing field"
  end
end

test "validate_with_arelle raises ConnectionError when service unavailable" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_raise(Errno::ECONNREFUSED)

  with_arelle_enabled do
    assert_raises(ArelleClient::ConnectionError) do
      @survey.validate_with_arelle
    end
  end
end

private

def with_arelle_enabled
  original = ENV["ARELLE_VALIDATION_ENABLED"]
  ENV["ARELLE_VALIDATION_ENABLED"] = "true"
  yield
ensure
  ENV["ARELLE_VALIDATION_ENABLED"] = original
end

def with_arelle_disabled
  original = ENV["ARELLE_VALIDATION_ENABLED"]
  ENV["ARELLE_VALIDATION_ENABLED"] = "false"
  yield
ensure
  ENV["ARELLE_VALIDATION_ENABLED"] = original
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/survey_test.rb -v -n /arelle/`
Expected: FAIL with "undefined method `validate_with_arelle'"

**Step 3: Write minimal implementation**

Add to `app/models/survey.rb` (after `completion_percentage` method, around line 49):

```ruby
# Validate XBRL output against Arelle API.
#
# Returns nil if Arelle validation is disabled.
# Returns ValidationResult with valid?, errors, error_messages.
# Raises ArelleClient::ConnectionError if Arelle is unavailable.
#
# @return [ArelleClient::ValidationResult, nil]
def validate_with_arelle
  return nil unless AmsfValidationConfig.arelle_enabled?

  client = ArelleClient.new
  client.validate(to_xbrl)
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/survey_test.rb -v -n /arelle/`
Expected: PASS (4 tests, 0 failures)

**Step 5: Commit**

```bash
git add app/models/survey.rb test/models/survey_test.rb
git commit -m "feat: add validate_with_arelle to Survey model

- Validate XBRL output against Arelle API
- Respect ARELLE_VALIDATION_ENABLED config
- Return ValidationResult or nil if disabled"
```

---

### Task 3: Block Completion on Validation Errors

**Files:**
- Modify: `app/controllers/submissions_controller.rb`
- Test: `test/controllers/submissions_controller_test.rb`

**Step 1: Write the failing test**

Add to `test/controllers/submissions_controller_test.rb`:

```ruby
# === Complete Action with Arelle Validation ===

test "complete action validates with arelle when enabled" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_return(
      status: 200,
      body: {valid: true, summary: {errors: 0}, messages: []}.to_json,
      headers: {"Content-Type" => "application/json"}
    )

  sign_in @user

  with_arelle_enabled do
    post complete_submission_path(@submission)
  end

  @submission.reload
  assert @submission.completed?
  assert_redirected_to submission_path(@submission)
end

test "complete action blocks completion when arelle returns errors" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_return(
      status: 200,
      body: {
        valid: false,
        summary: {errors: 2},
        messages: [
          {severity: "error", code: "a1101", message: "Missing required field a1101"},
          {severity: "error", code: "a1102", message: "Missing required field a1102"}
        ]
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    )

  sign_in @user

  with_arelle_enabled do
    post complete_submission_path(@submission)
  end

  @submission.reload
  assert @submission.draft?
  assert_response :unprocessable_entity
  assert_match /validation.*failed/i, flash[:alert]
end

test "complete action skips arelle when disabled" do
  sign_in @user

  with_arelle_disabled do
    post complete_submission_path(@submission)
  end

  @submission.reload
  assert @submission.completed?
end

test "complete action shows friendly error when arelle unavailable" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_raise(Errno::ECONNREFUSED)

  sign_in @user

  with_arelle_enabled do
    post complete_submission_path(@submission)
  end

  @submission.reload
  assert @submission.draft?
  assert_response :unprocessable_entity
  assert_match /validation service.*unavailable/i, flash[:alert]
end

private

def with_arelle_enabled
  original = ENV["ARELLE_VALIDATION_ENABLED"]
  ENV["ARELLE_VALIDATION_ENABLED"] = "true"
  yield
ensure
  ENV["ARELLE_VALIDATION_ENABLED"] = original
end

def with_arelle_disabled
  original = ENV["ARELLE_VALIDATION_ENABLED"]
  ENV["ARELLE_VALIDATION_ENABLED"] = "false"
  yield
ensure
  ENV["ARELLE_VALIDATION_ENABLED"] = original
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/submissions_controller_test.rb -v -n /complete.*arelle/`
Expected: FAIL (tests expect validation but controller doesn't do it yet)

**Step 3: Write minimal implementation**

Update `app/controllers/submissions_controller.rb` `complete` action (around line 55):

```ruby
# POST /submissions/:id/complete
def complete
  authorize @submission

  survey = Survey.new(organization: current_organization, year: @submission.year)

  # Validate with Arelle if enabled
  begin
    validation_result = survey.validate_with_arelle
    if validation_result && !validation_result.valid
      flash[:alert] = "XBRL validation failed with #{validation_result.summary[:errors]} error(s). Please fix the issues and try again."
      flash[:validation_errors] = validation_result.error_messages
      render :review, status: :unprocessable_entity
      return
    end
  rescue ArelleClient::ConnectionError => e
    Rails.logger.error("Arelle validation service unavailable: #{e.message}")
    flash[:alert] = "XBRL validation service is temporarily unavailable. Please try again later."
    render :review, status: :unprocessable_entity
    return
  end

  @submission.complete!
  redirect_to submission_path(@submission), notice: "Submission completed successfully."
end
```

**Step 4: Run test to verify it passes**

Run: `bin/rails test test/controllers/submissions_controller_test.rb -v -n /complete.*arelle/`
Expected: PASS (4 tests, 0 failures)

**Step 5: Commit**

```bash
git add app/controllers/submissions_controller.rb test/controllers/submissions_controller_test.rb
git commit -m "feat: validate with Arelle before completing submission

- Block completion if Arelle returns validation errors
- Show friendly error message when validation service unavailable
- Skip validation when ARELLE_VALIDATION_ENABLED is false"
```

---

### Task 4: Show Validation Errors in Review UI

**Files:**
- Modify: `app/views/submissions/review.html.erb`
- Create: `app/views/submissions/_validation_errors.html.erb`

**Step 1: Create validation errors partial**

Create `app/views/submissions/_validation_errors.html.erb`:

```erb
<%# Displays Arelle validation errors in review page %>
<% if flash[:validation_errors].present? %>
  <div class="rounded-md bg-red-50 p-4 mb-6" data-controller="validation-errors">
    <div class="flex">
      <div class="flex-shrink-0">
        <%= heroicon "x-circle", variant: :solid, options: { class: "h-5 w-5 text-red-400" } %>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-red-800">
          XBRL Validation Failed
        </h3>
        <div class="mt-2 text-sm text-red-700">
          <p class="mb-2">Please fix the following errors before completing your submission:</p>
          <ul class="list-disc pl-5 space-y-1">
            <% flash[:validation_errors].first(10).each do |error| %>
              <li><%= error %></li>
            <% end %>
            <% if flash[:validation_errors].size > 10 %>
              <li class="text-red-600 font-medium">
                ... and <%= flash[:validation_errors].size - 10 %> more error(s)
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

**Step 2: Add partial to review view**

Find `app/views/submissions/review.html.erb` and add at the top (after any page header):

```erb
<%= render "validation_errors" %>
```

**Step 3: Test manually**

1. Start arelle_api: `cd ../arelle_api && uv run uvicorn app.main:app --port 8000`
2. Enable Arelle validation: `ARELLE_VALIDATION_ENABLED=true bin/dev`
3. Go to a draft submission and click "Complete"
4. Verify errors are displayed in red box

**Step 4: Commit**

```bash
git add app/views/submissions/_validation_errors.html.erb app/views/submissions/review.html.erb
git commit -m "feat: display Arelle validation errors in review UI

- Add validation_errors partial with red alert styling
- Show first 10 errors with count of remaining
- Include in review page for validation feedback"
```

---

### Task 5: Add Validate Button for On-Demand Validation

**Files:**
- Modify: `app/controllers/submissions_controller.rb`
- Modify: `config/routes/crm.rb`
- Modify: `app/views/submissions/review.html.erb`
- Test: `test/controllers/submissions_controller_test.rb`

**Step 1: Write the failing test**

Add to `test/controllers/submissions_controller_test.rb`:

```ruby
# === Validate Action ===

test "validate action returns validation result" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_return(
      status: 200,
      body: {
        valid: false,
        summary: {errors: 1, warnings: 0, info: 2},
        messages: [{severity: "error", code: "test", message: "Test error"}]
      }.to_json,
      headers: {"Content-Type" => "application/json"}
    )

  sign_in @user

  with_arelle_enabled do
    post validate_submission_path(@submission)
  end

  assert_redirected_to review_submission_path(@submission)
  assert_equal ["Test error"], flash[:validation_errors]
end

test "validate action shows success when valid" do
  stub_request(:post, "http://localhost:8000/validate")
    .to_return(
      status: 200,
      body: {valid: true, summary: {errors: 0}, messages: []}.to_json,
      headers: {"Content-Type" => "application/json"}
    )

  sign_in @user

  with_arelle_enabled do
    post validate_submission_path(@submission)
  end

  assert_redirected_to review_submission_path(@submission)
  assert_match /valid/i, flash[:notice]
end
```

**Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/submissions_controller_test.rb -v -n /validate.*action/`
Expected: FAIL with "No route matches"

**Step 3: Add route**

Add to `config/routes/crm.rb` inside the submissions resource block:

```ruby
resources :submissions do
  member do
    get :download
    get :review
    post :complete
    post :validate  # Add this line
  end
end
```

**Step 4: Add controller action**

Add to `app/controllers/submissions_controller.rb`:

```ruby
# POST /submissions/:id/validate
def validate
  authorize @submission

  survey = Survey.new(organization: current_organization, year: @submission.year)

  begin
    result = survey.validate_with_arelle

    if result.nil?
      flash[:alert] = "XBRL validation is not enabled."
    elsif result.valid
      flash[:notice] = "XBRL validation passed! Your submission is ready to complete."
    else
      flash[:alert] = "XBRL validation found #{result.summary[:errors]} error(s)."
      flash[:validation_errors] = result.error_messages
    end
  rescue ArelleClient::ConnectionError => e
    Rails.logger.error("Arelle validation service unavailable: #{e.message}")
    flash[:alert] = "XBRL validation service is temporarily unavailable."
  end

  redirect_to review_submission_path(@submission)
end
```

**Step 5: Update before_action**

Update `before_action` to include `:validate`:

```ruby
before_action :set_submission, only: [:show, :edit, :update, :destroy, :download, :review, :complete, :validate]
```

**Step 6: Run test to verify it passes**

Run: `bin/rails test test/controllers/submissions_controller_test.rb -v -n /validate.*action/`
Expected: PASS (2 tests, 0 failures)

**Step 7: Add validate button to review page**

Add to `app/views/submissions/review.html.erb` (near the complete button):

```erb
<div class="flex gap-4">
  <%= button_to "Validate XBRL", validate_submission_path(@submission),
      method: :post,
      class: "btn btn-secondary",
      data: { turbo_frame: "_top" } %>

  <%= button_to "Complete Submission", complete_submission_path(@submission),
      method: :post,
      class: "btn btn-primary",
      data: { turbo_frame: "_top", confirm: "Are you sure you want to complete this submission?" } %>
</div>
```

**Step 8: Commit**

```bash
git add app/controllers/submissions_controller.rb config/routes/crm.rb \
        app/views/submissions/review.html.erb test/controllers/submissions_controller_test.rb
git commit -m "feat: add validate button for on-demand XBRL validation

- Add POST /submissions/:id/validate route and action
- Show validation results via flash messages
- Add Validate XBRL button to review page"
```

---

### Task 6: Run Full Test Suite and Verify

**Step 1: Run all tests**

Run: `bin/rails test`
Expected: All tests pass

**Step 2: Run specific integration tests**

Run: `bin/rails test test/clients/arelle_client_test.rb test/models/survey_test.rb test/controllers/submissions_controller_test.rb -v`
Expected: All tests pass

**Step 3: Manual smoke test**

1. Start arelle_api: `cd ../arelle_api && uv run uvicorn app.main:app --port 8000`
2. Start immo_crm: `ARELLE_VALIDATION_ENABLED=true bin/dev`
3. Navigate to a draft submission
4. Click "Review"
5. Click "Validate XBRL" - should show errors (incomplete submission)
6. Click "Complete Submission" - should be blocked with errors shown
7. Verify errors display correctly in red alert box

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: finalize Arelle validation integration

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Summary

This plan adds Arelle XBRL validation to immo_crm with:

1. **ArelleClient** - HTTP client for the arelle_api service
2. **Survey#validate_with_arelle** - Method to validate XBRL output
3. **Completion blocking** - Prevent completing submissions with validation errors
4. **UI feedback** - Show validation errors in the review page
5. **On-demand validation** - "Validate XBRL" button for testing before completion

Configuration:
- `ARELLE_VALIDATION_ENABLED=true` enables validation (default: false in dev, true in prod)
- `ARELLE_API_URL` configures the API endpoint (default: http://localhost:8000)
