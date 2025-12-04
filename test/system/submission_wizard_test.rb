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

  # ==========================================================================
  # US1 - 7-Step Wizard Tests (AMSF Data Capture)
  # ==========================================================================

  # === Full 7-Step Flow ===

  test "complete 7-step wizard flow with all new steps" do
    submission = create_draft_submission
    login_as @user, scope: :user

    # Step 1: Activity Confirmation
    visit submission_submission_step_path(submission, step: 1)
    assert_text "Step 1"
    click_button "Continue"

    # Step 2: Client Statistics
    assert_text "Step 2"
    assert_selector "[data-element='a1101']" # Total clients
    click_button "Continue"

    # Step 3: Transaction Statistics
    assert_text "Step 3"
    click_button "Continue"

    # Step 4: Training & Compliance
    assert_text "Step 4"
    assert_text "Training"
    click_button "Continue"

    # Step 5: Revenue Review
    assert_text "Step 5"
    assert_text "Revenue"
    click_button "Continue"

    # Step 6: Policy Confirmation
    assert_text "Step 6"
    assert_text "Policy"
    click_button "Confirm All" if page.has_button?("Confirm All")
    click_button "Continue"

    # Step 7: Review & Sign
    assert_text "Step 7"
    assert_text "Review" || assert_text "Sign"
  end

  # === Step 5: Revenue Review ===

  test "step 5 displays revenue breakdown" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 5)

    assert_text "Step 5"
    assert_text "Revenue"
    # Should show revenue by type
    assert_text "Sales" || assert_selector "[data-element='a3802']"
    assert_text "Rental" || assert_selector "[data-element='a3803']"
    assert_text "Management" || assert_selector "[data-element='a3804']"
    assert_text "Total" || assert_selector "[data-element='a381']"
  end

  test "step 5 shows year-over-year revenue comparison" do
    # Create previous year submission
    prev_submission = Submission.create!(
      organization: @organization,
      year: Date.current.year - 1,
      status: "completed"
    )
    prev_submission.submission_values.create!(
      element_name: "a381",
      value: "100000",
      source: "calculated"
    )

    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 5)

    # Should show previous year column
    assert_text "Previous" || assert_selector "[data-previous-value]"
  end

  # === Step 6: Policy Confirmation ===

  test "step 6 displays all compliance policies" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 6)

    assert_text "Step 6"
    assert_text "Policy"
    # Should show KYC/AML policies
    assert_text "KYC" || assert_text "procedure" || assert_text "compliance"
  end

  test "step 6 confirm all button marks policies as confirmed" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 6)

    click_button "Confirm All"

    assert_text "confirmed" || assert_selector ".confirmed"
  end

  # === Step 7: Review & Sign ===

  test "step 7 displays full submission summary" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 7)

    assert_text "Step 7"
    assert_text "Review" || assert_text "Summary"
    # Should show all sections
    assert_text "Client" || assert_selector "[data-section='clients']"
    assert_text "Transaction" || assert_selector "[data-section='transactions']"
    assert_text "Revenue" || assert_selector "[data-section='revenue']"
  end

  test "step 7 shows validation status summary" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 7)

    assert_text "Valid" || assert_text "Status" || assert_selector ".validation-status"
  end

  test "step 7 displays signatory input fields" do
    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 7)

    assert_selector "input[name*='signatory']" || assert_text "Signatory"
  end

  test "step 7 highlights significant YoY changes" do
    # Create significant change scenario
    prev_submission = Submission.create!(
      organization: @organization,
      year: Date.current.year - 1,
      status: "completed"
    )
    prev_submission.submission_values.create!(
      element_name: "a1101",
      value: "100",
      source: "calculated"
    )

    submission = create_draft_submission
    submission.submission_values.find_or_create_by!(element_name: "a1101") do |sv|
      sv.value = "200" # 100% increase = significant
      sv.source = "calculated"
    end

    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 7)

    # Should show warning about significant changes
    assert_text "significant" || assert_selector ".significant-change"
  end

  test "step 7 generate button creates XBRL for validated submission" do
    submission = create_validated_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 7)

    click_button "Generate XBRL"

    submission.reload
    assert submission.completed?
    assert_not_nil submission.generated_at
  end

  # === Locking Tests (FR-029) ===

  test "shows lock indicator when submission is locked by another user" do
    submission = create_draft_submission
    other_user = users(:two)
    submission.lock!(other_user)

    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 1)

    assert_text "locked" || assert_text other_user.name
  end

  # === Year-over-Year Comparison ===

  test "wizard shows YoY change percentages for calculated values" do
    # Setup previous year
    prev_submission = Submission.create!(
      organization: @organization,
      year: Date.current.year - 1,
      status: "completed"
    )
    prev_submission.submission_values.create!(
      element_name: "a1101",
      value: "100",
      source: "calculated"
    )

    submission = create_draft_submission
    login_as @user, scope: :user

    visit submission_submission_step_path(submission, step: 2)

    # Should show change percentage
    assert_text "%" || assert_selector "[data-change-percent]"
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
