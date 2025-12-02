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

    # Values should be calculated
    assert @submission.submission_values.any?
  end

  test "step 1 update saves overridden values" do
    sign_in @user

    # First populate values
    CalculationEngine.new(@submission).populate_submission_values!

    patch submission_submission_step_path(@submission, step: 1), params: {
      submission: {
        submission_values_attributes: {
          "0" => {
            id: @submission.submission_values.first.id,
            value: "999"
          }
        }
      }
    }

    value = @submission.submission_values.first.reload
    assert_equal "999", value.value
    assert value.overridden
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

  # === Step 4: Validate & Download ===

  test "shows step 4 validate and download" do
    sign_in @user

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_select "h1", /Validate|Download/i
  end

  test "step 4 triggers validation on load" do
    sign_in @user

    # Stub the validation service
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
  end

  test "step 4 shows validation success" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /pass|success|valid/i, response.body
  end

  test "step 4 shows validation errors" do
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

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /error|fail/i, response.body
  end

  test "step 4 shows validation warnings" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: true,
          errors: [],
          warnings: [{ code: "WARN001", message: "High cash ratio" }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /warn/i, response.body
  end

  test "step 4 shows service unavailable message" do
    sign_in @user

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_timeout

    get submission_submission_step_path(@submission, step: 4)
    assert_response :success
    assert_match /unavailable|unable/i, response.body
  end

  test "step 4 can go back to step 3" do
    sign_in @user

    patch submission_submission_step_path(@submission, step: 4), params: {
      commit: "back"
    }

    assert_redirected_to submission_submission_step_path(@submission, step: 3)
  end

  test "step 4 complete marks submission as completed" do
    validated_submission = submissions(:validated_submission)
    sign_in @user

    patch submission_submission_step_path(validated_submission, step: 4), params: {
      commit: "complete"
    }

    validated_submission.reload
    assert_equal "completed", validated_submission.status
    assert_not_nil validated_submission.completed_at
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
end
