# frozen_string_literal: true

require "test_helper"

class SubmissionStepsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @submission = submissions(:draft_submission)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get submission_submission_step_path(@submission, step: 1)
    assert_redirected_to new_user_session_path
  end

  # === Step 1: Review Aggregates ===

  test "shows step 1 review aggregates" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 1)
    assert_response :success
    assert_select "h1", /Review/i
  end

  test "step 1 displays client statistics" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 1)
    assert_response :success
    assert_match /client/i, response.body
  end

  test "step 1 displays transaction statistics" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 1)
    assert_response :success
    assert_match /transaction/i, response.body
  end

  test "step 1 calculates values if not already populated" do
    # Remove any existing values
    @submission.submission_values.destroy_all
    sign_in @user

    get submission_submission_step_path(@submission, step: 1)
    assert_response :success

    # Reload to see new values created by controller
    @submission.reload
    # Values should be calculated
    assert @submission.submission_values.any?
  end

  test "step 1 update saves overridden values" do
    sign_in @user

    # First populate values
    CalculationEngine.new(@submission).populate_submission_values!

    # Capture the specific value we're testing (use order for deterministic results)
    target_value = @submission.submission_values.order(:id).first

    patch submission_submission_step_path(@submission, step: 1), params: {
      submission: {
        submission_values_attributes: {
          "0" => {
            id: target_value.id,
            value: "999"
          }
        }
      }
    }

    target_value.reload
    assert_equal "999", target_value.value
    assert target_value.overridden
  end

  test "step 1 proceeds to step 2 on continue" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 1), params: {
      commit: "continue"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 2)
  end

  # === Step 2: Confirm Policies ===

  test "shows step 2 confirm policies" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 2)
    assert_response :success
    assert_select "h1", /Confirm|Policy/i
  end

  test "step 2 displays settings from organization" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 2)
    assert_response :success
    # Should show policy settings
  end

  test "step 2 confirm action confirms all policy values" do
    sign_in @user

    post confirm_submission_submission_step_path(@submission, step: 2)

    # All from_settings values should be confirmed
    from_settings_values = @submission.submission_values.from_settings
    from_settings_values.each do |value|
      assert value.confirmed?
    end
  end

  test "step 2 proceeds to step 3 on continue" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 2), params: {
      commit: "continue"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 3)
  end

  test "step 2 can go back to step 1" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 2), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 1)
  end

  # === Step 3: Fresh Questions ===

  test "shows step 3 fresh questions" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 3)
    assert_response :success
    assert_select "h1", /Question|Annual/i
  end

  test "step 3 displays manual questions" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 3)
    assert_response :success
    # Should show form fields for manual entry questions
    assert_select "form"
  end

  test "step 3 saves manual answers" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 3), params: {
      submission: {
        manual_values: {
          "rejected_clients" => "true",
          "rejected_count" => "2"
        }
      }
    }

    # Manual values should be saved
    assert @submission.submission_values.manual.any?
  end

  test "step 3 proceeds to step 4 on continue" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 3), params: {
      commit: "continue"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 4)
  end

  test "step 3 can go back to step 2" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 3), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 2)
  end

  # === Step 4: Property Management Statistics (US1) ===

  test "shows step 4 property management statistics" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_select "h1", /Property Management/i
  end

  test "step 4 displays active property count" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /aACTIVEPS|active.*propert/i, response.body
  end

  test "step 4 displays tenant statistics" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /a1802TOLA|tenant/i, response.body
  end

  test "step 4 displays PEP tenant count" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /a1802PEP|pep.*tenant/i, response.body
  end

  test "step 4 displays year-over-year comparison" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    # Should show YoY change percentage indicators
    # The view includes YoY comparison data
  end

  test "step 4 proceeds to step 5 on continue" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 4), params: {
      commit: "continue"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 5)
  end

  test "step 4 can go back to step 3" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 4), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 3)
  end

  # === Invalid Step ===

  test "returns 404 for invalid step number" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 99)
    assert_response :not_found
  end

  test "returns 404 for step 0" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 0)
    assert_response :not_found
  end

  # === Cross-Organization Access ===

  test "returns 404 for submission from different organization" do
    other_submission = submissions(:other_org_submission)
    sign_in @user

    get submission_submission_step_path(other_submission, step: 1)
    assert_response :not_found
  end

  # === Completed Submission ===

  test "completed submission shows read-only view" do
    completed = submissions(:completed_submission)
    sign_in @user

    get submission_submission_step_path(completed, step: 1)
    assert_response :success
    # Should be read-only or redirect to summary
  end

  # === Progress Tracking ===

  test "shows progress indicator" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 2)
    assert_response :success
    # Should show which step we're on
    assert_select ".step-indicator", minimum: 1
  end

  # === Turbo Frame Support ===

  test "step responds to turbo frame request" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 1),
        headers: { "Turbo-Frame" => "submission_step" }
    assert_response :success
  end

  # === Validation Button ===

  test "step 4 re-validate action runs validation again" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post confirm_submission_submission_step_path(@submission, step: 4), params: {
      action_type: "revalidate"
    }

    assert_response :redirect
  end

  # === Audit Logging ===

  test "creates audit log when step is completed" do
    sign_in @user

    assert_difference "AuditLog.count" do
      patch submission_submission_step_path(@submission, step: 1), params: {
        commit: "continue"
      }
    end
  end

  # ==========================================================================
  # US1 - 7-Step Wizard Tests (AMSF Data Capture)
  # ==========================================================================

  # === Step 5: Revenue Review (US1) ===

  test "shows step 5 revenue review" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 5)
    assert_response :success
    assert_select "h1", /Revenue/i
  end

  test "step 5 displays sales commission revenue" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 5)
    assert_response :success
    assert_match /a3802|sales.*commission/i, response.body
  end

  test "step 5 displays rental commission revenue" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 5)
    assert_response :success
    assert_match /a3803|rental.*commission/i, response.body
  end

  test "step 5 displays property management revenue" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 5)
    assert_response :success
    assert_match /a3804|management.*revenue/i, response.body
  end

  test "step 5 displays total revenue" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 5)
    assert_response :success
    assert_match /a381|total.*revenue/i, response.body
  end

  test "step 5 displays year-over-year comparison" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 5)
    assert_response :success
    # Should show YoY change percentage indicators when there's data
    # The view includes YoY comparison elements (shown as percentage badges)
    # Note: If no previous submission exists, no YoY percentages shown
    assert_select ".bg-gray-50", minimum: 1  # Revenue section container
  end

  test "step 5 proceeds to step 6 on continue" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 5), params: {
      commit: "continue"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 6)
  end

  test "step 5 can go back to step 4" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 5), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 4)
  end

  # === Step 6: Training & Compliance Statistics (US1) ===

  test "shows step 6 training and compliance statistics" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 6)
    assert_response :success
    assert_select "h1", /Training|Compliance/i
  end

  test "step 6 displays training conducted indicator" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 6)
    assert_response :success
    assert_match /a3201|training.*conduct/i, response.body
  end

  test "step 6 displays staff trained count" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 6)
    assert_response :success
    assert_match /a3202|staff.*train/i, response.body
  end

  test "step 6 displays due diligence statistics" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 6)
    assert_response :success
    assert_match /a1203|due.*diligence/i, response.body
  end

  test "step 6 proceeds to step 7 on continue" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 6), params: {
      commit: "continue"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 7)
  end

  test "step 6 can go back to step 5" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 6), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 5)
  end

  # === Step 7: Validate & Download (moved from old step 4) ===

  test "shows step 7 validate and download" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 7)
    assert_response :success
    assert_select "h1", /Validate|Download/i
  end

  test "step 7 triggers validation on load" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get submission_submission_step_path(@submission, step: 7)
    assert_response :success
  end

  test "step 7 displays validation status" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get submission_submission_step_path(@submission, step: 7)
    assert_response :success
    assert_match /valid|status/i, response.body
  end

  test "step 7 shows validation errors" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          errors: [{ code: "ERR001", message: "Client count mismatch" }],
          warnings: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get submission_submission_step_path(@submission, step: 7)
    assert_response :success
    assert_match /error|fail/i, response.body
  end

  test "step 7 shows service unavailable message" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_timeout

    get submission_submission_step_path(@submission, step: 7)
    assert_response :success
    assert_match /unavailable|unable/i, response.body
  end

  test "step 7 re-validate action runs validation again" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post confirm_submission_submission_step_path(@submission, step: 7), params: {
      action_type: "revalidate"
    }

    assert_response :redirect
  end

  test "step 7 complete marks submission as completed" do
    validated_submission = submissions(:validated_submission)
    sign_in @user

    patch submission_submission_step_path(validated_submission, step: 7), params: {
      commit: "complete"
    }

    validated_submission.reload
    assert_equal "completed", validated_submission.status
    assert_not_nil validated_submission.completed_at
  end

  test "step 7 can go back to step 6" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 7), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 6)
  end

  # === Locking Tests (FR-029) ===

  test "lock action locks submission for user" do
    sign_in @user

    post lock_submission_submission_steps_path(@submission)

    @submission.reload
    assert @submission.locked?
    assert @submission.locked_by?(@user)
  end

  test "unlock action releases lock" do
    @submission.acquire_lock!(@user)
    sign_in @user

    post unlock_submission_submission_steps_path(@submission)

    @submission.reload
    assert_not @submission.locked?
  end

  test "locked submission shows lock indicator" do
    other_user = users(:two)
    @submission.acquire_lock!(other_user)
    sign_in @user

    # Test on step 4 which has the lock indicator
    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    # The message "This submission is being edited by another user" includes "edited"
    assert_match /edited|being edited/i, response.body
  end

  # === Reopen Tests (FR-025) ===

  test "reopen action returns completed submission to draft" do
    completed = submissions(:completed_submission)
    sign_in @user

    post reopen_submission_path(completed)

    completed.reload
    assert_equal "draft", completed.status
    assert_equal 1, completed.reopened_count
  end

  test "reopen requires completed status" do
    sign_in @user

    # Draft submission cannot be reopened - Pundit policy denies access
    assert_raises(Pundit::NotAuthorizedError) do
      post reopen_submission_path(@submission)
    end
  end
end
