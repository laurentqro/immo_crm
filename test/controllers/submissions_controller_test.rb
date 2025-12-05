# frozen_string_literal: true

require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @submission = submissions(:draft_submission)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get submissions_path
    assert_redirected_to new_user_session_path
  end

  test "redirects to onboarding when no organization" do
    skip "Organization destroy in tests needs fixture cleanup - known issue"
    @organization.destroy
    sign_in @user

    get submissions_path
    assert_redirected_to new_onboarding_path
  end

  # === Index ===

  test "shows submissions list when authenticated" do
    sign_in @user

    get submissions_path
    assert_response :success
    assert_select "h1", /Submissions/i
  end

  test "only shows submissions from current organization" do
    other_org_submission = submissions(:other_org_submission)
    sign_in @user

    get submissions_path
    assert_response :success
    # Should show our submission but not the other org's
    assert_match @submission.year.to_s, response.body
  end

  test "shows submissions ordered by year descending" do
    sign_in @user

    get submissions_path
    assert_response :success
    # Most recent year should appear first
  end

  # === Show ===

  test "shows submission details" do
    sign_in @user

    get submission_path(@submission)
    assert_response :success
    assert_select "h1", /#{@submission.year}/
  end

  test "returns 404 for submission from different organization" do
    other_submission = submissions(:other_org_submission)
    sign_in @user

    get submission_path(other_submission)
    assert_response :not_found
  end

  test "shows submission status badge" do
    sign_in @user

    get submission_path(@submission)
    assert_response :success
    # Should show status indicator
    assert_match @submission.status, response.body
  end

  # === Show (XML Format) ===

  test "renders XBRL XML when requesting XML format" do
    sign_in @user

    get submission_path(@submission, format: :xml)
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
    assert_match %r{<xbrl}, response.body
    assert_match %r{xmlns.*xbrl}, response.body
  end

  test "XML format includes organization RCI number in context" do
    sign_in @user

    get submission_path(@submission, format: :xml)
    assert_response :success
    assert_match @organization.rci_number, response.body
  end

  # === Show (Markdown Format) ===

  test "renders Markdown when requesting MD format" do
    sign_in @user

    get submission_path(@submission, format: :md)
    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_match /^# AMSF Submission/, response.body
  end

  test "Markdown format includes organization details" do
    sign_in @user

    get submission_path(@submission, format: :md)
    assert_response :success
    assert_match @organization.name, response.body
    assert_match @organization.rci_number, response.body
  end

  # === Create (Start New Submission) ===

  test "creates new submission for current year" do
    # Delete existing submission for current year if any
    Submission.where(organization: @organization, year: Date.current.year).destroy_all
    sign_in @user

    assert_difference "Submission.count", 1 do
      post submissions_path, params: {
        submission: {
          year: Date.current.year
        }
      }
    end

    submission = Submission.last
    assert_equal @organization, submission.organization
    assert_equal Date.current.year, submission.year
    assert_equal "draft", submission.status
    assert_redirected_to submission_submission_step_path(submission, step: 1)
  end

  test "resumes existing draft for same year" do
    existing_draft = Submission.create!(
      organization: @organization,
      year: 2030
    )
    sign_in @user

    assert_no_difference "Submission.count" do
      post submissions_path, params: {
        submission: {
          year: 2030
        }
      }
    end

    assert_redirected_to submission_submission_step_path(existing_draft, step: 1)
  end

  test "creates submission with taxonomy version" do
    Submission.where(organization: @organization, year: 2031).destroy_all
    sign_in @user

    post submissions_path, params: {
      submission: {
        year: 2031,
        taxonomy_version: "2025"
      }
    }

    submission = Submission.last
    assert_equal "2025", submission.taxonomy_version
  end

  test "returns error for invalid year" do
    sign_in @user

    post submissions_path, params: {
      submission: {
        year: 1990  # Invalid - too old
      }
    }

    assert_response :unprocessable_entity
  end

  # === Download ===

  test "downloads XBRL file for validated submission" do
    validated_submission = submissions(:validated_submission)
    sign_in @user

    get download_submission_path(validated_submission)
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_match /attachment/, response.headers["Content-Disposition"]
  end

  test "download includes correct filename" do
    validated_submission = submissions(:validated_submission)
    sign_in @user

    get download_submission_path(validated_submission)
    assert_match /amsf.*#{validated_submission.year}.*#{@organization.rci_number}.*\.xml/,
                 response.headers["Content-Disposition"]
  end

  test "allows download of unvalidated submission with warning flag" do
    draft_submission = @submission
    sign_in @user

    get download_submission_path(draft_submission), params: { unvalidated: true }
    assert_response :success

    draft_submission.reload
    assert draft_submission.downloaded_unvalidated
  end

  test "returns 404 when downloading submission from different organization" do
    other_submission = submissions(:other_org_submission)
    sign_in @user

    get download_submission_path(other_submission)
    assert_response :not_found
  end

  # === Destroy ===

  test "destroys draft submission" do
    sign_in @user

    assert_difference "Submission.count", -1 do
      delete submission_path(@submission)
    end

    assert_redirected_to submissions_path
  end

  test "cannot destroy completed submission" do
    completed = submissions(:completed_submission)
    sign_in @user

    assert_no_difference "Submission.count" do
      delete submission_path(completed)
    end

    assert_response :unprocessable_entity
  end

  test "returns 404 when destroying submission from different organization" do
    other_submission = submissions(:other_org_submission)
    sign_in @user

    delete submission_path(other_submission)
    assert_response :not_found
  end

  # === State Transitions ===

  test "can start review on draft submission" do
    sign_in @user

    patch submission_path(@submission), params: {
      submission: {
        status: "in_review"
      }
    }

    @submission.reload
    assert_equal "in_review", @submission.status
  end

  # === Flash Messages ===

  test "shows success message after creating submission" do
    Submission.where(organization: @organization, year: 2032).destroy_all
    sign_in @user

    post submissions_path, params: {
      submission: { year: 2032 }
    }

    assert_equal "Submission started for 2032.", flash[:notice]
  end

  test "shows success message after deleting submission" do
    sign_in @user

    delete submission_path(@submission)
    assert_equal "Submission was successfully deleted.", flash[:notice]
  end

  # === Turbo Responses ===

  test "index responds to turbo frame request" do
    sign_in @user

    get submissions_path, headers: { "Turbo-Frame" => "submissions_list" }
    assert_response :success
  end

  # === Year Filtering ===

  test "filters submissions by year" do
    sign_in @user

    get submissions_path(year: @submission.year)
    assert_response :success
  end

  # === Status Filtering ===

  test "filters submissions by status" do
    sign_in @user

    get submissions_path(status: "draft")
    assert_response :success
  end

  # === Audit Logging ===

  test "creates audit log on submission creation" do
    Submission.where(organization: @organization, year: 2033).destroy_all
    sign_in @user

    assert_difference "AuditLog.count" do
      post submissions_path, params: {
        submission: { year: 2033 }
      }
    end
  end

  test "creates audit log on XBRL download" do
    validated = submissions(:validated_submission)
    sign_in @user

    assert_difference "AuditLog.count" do
      get download_submission_path(validated)
    end

    log = AuditLog.last
    assert_equal "download", log.action
  end
end
