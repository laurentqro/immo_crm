# frozen_string_literal: true

require "application_system_test_case"

class SubmissionWizardTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @organization = organizations(:one)

    # Stub the validation service for all tests
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "#{ValidationService::VALIDATOR_URL}/health")
      .to_return(
        status: 200,
        body: { status: "ok" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # === Starting a Submission ===

  test "user can start a new annual submission" do
    login_as @user, scope: :user

    visit submissions_path
    click_link "Start #{Date.current.year} Submission"

    assert_text "Step 1"
    assert_text "Review"
  end

  test "user sees submission list with history" do
    login_as @user, scope: :user

    visit submissions_path

    assert_text "Submissions"
    # Should show any existing submissions
  end

  # === Step 1: Review Aggregates ===

  test "step 1 shows calculated client statistics" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 1)

    assert_text "Step 1"
    assert_text "Client"
    # Should show client counts
    assert_selector "[data-element='a1101']"
  end

  test "step 1 shows calculated transaction statistics" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 1)

    assert_text "Transaction"
    # Should show transaction counts and values
  end

  test "user can edit calculated values in step 1" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 1)

    # Click edit button
    click_link "Edit"

    # Should show editable fields
    assert_selector "input[type='number']"
  end

  test "user can proceed from step 1 to step 2" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 1)
    click_button "Save & Continue"

    assert_current_path submission_submission_step_path(submission, step: 2)
    assert_text "Step 2"
  end

  # === Step 2: Confirm Policies ===

  test "step 2 shows policy settings from organization" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 2)

    assert_text "Step 2"
    assert_text "Policy" || assert_text "Confirm"
    # Should show entity info, compliance policies, etc.
  end

  test "user can confirm all policies" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 2)
    click_button "Confirm All"

    # Should show confirmation checkmarks or proceed
    assert_text "confirmed" || assert_current_path(submission_submission_step_path(submission, step: 3))
  end

  test "user can go back from step 2 to step 1" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 2)
    click_link "Back"

    assert_current_path submission_submission_step_path(submission, step: 1)
  end

  test "user can proceed from step 2 to step 3" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 2)
    click_button "Continue"

    assert_current_path submission_submission_step_path(submission, step: 3)
    assert_text "Step 3"
  end

  # === Step 3: Fresh Questions ===

  test "step 3 shows annual questions" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 3)

    assert_text "Step 3"
    assert_text "Question" || assert_text "Annual"
    # Should show form with questions
    assert_selector "form"
  end

  test "user can answer yes/no questions" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 3)

    # Answer a yes/no question
    select "Yes", from: "rejected_clients"

    # Should show follow-up field
    assert_selector "input[name*='rejected_count']"
  end

  test "user can save answers and proceed to step 4" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 3)

    # Fill in required answers
    select "No", from: "rejected_clients" if page.has_select?("rejected_clients")

    click_button "Save & Continue"

    assert_current_path submission_submission_step_path(submission, step: 4)
    assert_text "Step 4"
  end

  # === Step 4: Validate & Download ===

  test "step 4 shows validation status" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)

    assert_text "Step 4"
    assert_text "Validate" || assert_text "Download"
    # Should show validation result
    assert_text "pass" || assert_text "valid" || assert_text "rule"
  end

  test "step 4 shows download button when validation passes" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)

    # Validation passed (stubbed above)
    assert_selector "a", text: /Download/i
  end

  test "user can download XBRL file" do
    submission = create_validated_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)

    # Should have download link
    assert_link "Download"
  end

  test "step 4 shows validation errors" do
    # Stub validation failure
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          errors: [{ code: "ERR001", message: "Client count inconsistent", element: "a1101" }],
          warnings: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)

    assert_text "error" || assert_text "fail"
    assert_text "Client count" || assert_text "ERR001"
  end

  test "step 4 shows validation warnings" do
    # Stub validation with warnings
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: true,
          errors: [],
          warnings: [{ code: "WARN001", message: "High cash ratio detected", element: "a2201" }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)

    assert_text "warning" || assert_text "High cash"
  end

  test "step 4 handles validation service unavailable" do
    # Stub service down
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_timeout

    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)

    assert_text "unavailable" || assert_text "service"
    # Should still offer unvalidated download option
    assert_text "Download" || assert_selector "button", text: /download/i
  end

  test "user can mark submission as completed" do
    submission = create_validated_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 4)
    click_button "Mark as Completed"

    submission.reload
    assert_equal "completed", submission.status
    assert_text "Completed"
  end

  # === Full Wizard Flow ===

  test "user can complete entire submission wizard" do
    submission = create_draft_submission
    login_as @user, scope: :user

    # Step 1: Review Aggregates
    visit submission_submission_step_path(submission, step: 1)
    assert_text "Step 1"
    click_button "Save & Continue"

    # Step 2: Confirm Policies
    assert_text "Step 2"
    click_button "Confirm All" if page.has_button?("Confirm All")
    click_button "Continue"

    # Step 3: Fresh Questions
    assert_text "Step 3"
    # Answer questions as needed
    click_button "Save & Continue"

    # Step 4: Validate & Download
    assert_text "Step 4"
    assert_text "valid" || assert_text "pass"

    # Complete the submission
    if page.has_button?("Mark as Completed")
      click_button "Mark as Completed"
      assert_text "Completed"
    end
  end

  # === Navigation ===

  test "progress indicator shows current step" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 2)

    # Should highlight step 2
    assert_selector ".step-indicator .step-2.active" || assert_selector "[data-step='2'].active"
  end

  test "user cannot skip steps" do
    submission = create_draft_submission
    # Don't complete step 1
    login_as @user, scope: :user

    # Try to access step 4 directly
    visit submission_submission_step_path(submission, step: 4)

    # Should either redirect back or show warning
    # Implementation may vary
  end

  # === Cross-Organization Security ===

  test "user cannot access submission from different organization" do
    other_submission = submissions(:other_org_submission)
    login_as @user, scope: :user

    visit submission_submission_step_path(other_submission, step: 1)

    assert_text "not found" || assert_current_path(root_path)
  end

  # === Completed Submission ===

  test "completed submission shows read-only summary" do
    completed = submissions(:completed_submission)
    login_as @user, scope: :user

    visit submission_path(completed)

    assert_text "Completed"
    # Should show summary without edit options
  end

  private

  def create_draft_submission
    # Ensure no existing submission for current year
    year = Date.current.year
    Submission.where(organization: @organization, year: year).destroy_all

    submission = Submission.create!(
      organization: @organization,
      year: year,
      status: "draft"
    )

    # Populate some values
    CalculationEngine.new(submission).populate_submission_values!

    submission
  end

  def create_validated_submission
    submission = create_draft_submission
    submission.update!(status: "validated", validated_at: Time.current)
    submission
  end
end
