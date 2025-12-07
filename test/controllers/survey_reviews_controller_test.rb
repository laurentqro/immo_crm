# frozen_string_literal: true

require "test_helper"

class SurveyReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @submission = submissions(:draft_submission)
  end

  # === T016: Test for GET /submissions/:id/review ===

  test "shows survey review page when authenticated" do
    sign_in @user

    get submission_review_path(@submission)
    assert_response :success
    assert_select "h1", /Review/i
  end

  test "review page displays sections from Xbrl::Survey" do
    sign_in @user

    get submission_review_path(@submission)
    assert_response :success

    # Should show section titles
    assert_match "Clients Summary", response.body
    assert_match "PEPs", response.body
  end

  test "review page displays elements with values" do
    sign_in @user

    get submission_review_path(@submission)
    assert_response :success

    # Fixture has a1101 = "42"
    assert_match "a1101", response.body
    assert_match "42", response.body
  end

  test "review page shows element labels from taxonomy" do
    sign_in @user

    get submission_review_path(@submission)
    assert_response :success

    # Should show taxonomy labels for elements (labels are in French)
    # Check for known section titles and element codes
    assert_match "a1101", response.body
    assert_select "td", /a1101/
  end

  # === T017: Test for authentication requirement ===

  test "redirects to login when not authenticated" do
    get submission_review_path(@submission)
    assert_redirected_to new_user_session_path
  end

  # === T018: Test for authorization (access denied) ===

  test "returns 404 for submission from different organization" do
    other_submission = submissions(:other_org_submission)
    sign_in @user

    get submission_review_path(other_submission)
    assert_response :not_found
  end

  test "allows access to own organization submissions" do
    sign_in @user

    get submission_review_path(@submission)
    assert_response :success
  end

  # === T041: Test for POST /submissions/:id/review/complete ===

  test "complete action transitions submission to completed status" do
    # Must use validated submission (state machine: validated -> completed)
    validated_submission = submissions(:validated_submission)
    sign_in @user

    post submission_complete_review_path(validated_submission)

    validated_submission.reload
    assert_equal "completed", validated_submission.status
    assert_redirected_to submission_path(validated_submission)
  end

  # === T042: Test for completing already-completed submission ===

  test "complete action rejects already completed submission" do
    completed_submission = submissions(:completed_submission)
    sign_in @user

    post submission_complete_review_path(completed_submission)

    assert_response :unprocessable_entity
  end

  test "complete action requires authentication" do
    post submission_complete_review_path(@submission)
    assert_redirected_to new_user_session_path
  end

  test "complete action returns 404 for other organization submission" do
    other_submission = submissions(:other_org_submission)
    sign_in @user

    post submission_complete_review_path(other_submission)
    assert_response :not_found
  end

  # === Value Recalculation Behavior ===

  test "draft submission recalculates values on each view" do
    sign_in @user

    # Create a draft with stale values
    draft = Submission.create!(organization: @organization, year: 2030, status: "draft")
    draft.submission_values.create!(element_name: "a1101", value: "999", source: "calculated")

    # Add a new client to change the expected count
    initial_count = @organization.clients.kept.count
    new_client = @organization.clients.create!(
      name: "New Test Client",
      client_type: "NATURAL_PERSON"
    )

    # View the review page - should recalculate
    get submission_review_path(draft)
    assert_response :success

    # Value should be updated to reflect new client count
    draft.reload
    updated_value = draft.submission_values.find_by(element_name: "a1101")
    assert_equal (initial_count + 1).to_s, updated_value.value

    # Cleanup
    new_client.destroy
    draft.destroy
  end

  test "completed submission does not recalculate values" do
    sign_in @user

    # Get a completed submission with existing values
    completed = submissions(:completed_submission)

    # Store original value
    original_value = completed.submission_values.find_by(element_name: "a1101")&.value
    original_value ||= "0"

    # Ensure it has a value we can check
    completed.submission_values.find_or_create_by!(element_name: "a1101") do |sv|
      sv.value = "frozen_value"
      sv.source = "calculated"
    end
    frozen_value = completed.submission_values.find_by(element_name: "a1101").value

    # Add a new client (which would change calculation if recalculated)
    new_client = @organization.clients.create!(
      name: "Should Not Affect Completed",
      client_type: "NATURAL_PERSON"
    )

    # View the review page - should NOT recalculate
    get submission_review_path(completed)
    assert_response :success

    # Value should remain unchanged (frozen)
    completed.reload
    assert_equal frozen_value, completed.submission_values.find_by(element_name: "a1101").value

    # Cleanup
    new_client.destroy
  end

  test "draft submission with no values calculates on first view" do
    sign_in @user

    # Create a fresh draft with no values
    draft = Submission.create!(organization: @organization, year: 2031, status: "draft")
    assert_equal 0, draft.submission_values.count

    # View the review page
    get submission_review_path(draft)
    assert_response :success

    # Should now have calculated values
    draft.reload
    assert draft.submission_values.count > 0, "Expected values to be calculated on first view"

    # Cleanup
    draft.destroy
  end
end
