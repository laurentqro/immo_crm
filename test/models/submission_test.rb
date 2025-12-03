# frozen_string_literal: true

require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid submission with required attributes" do
    submission = Submission.new(
      organization: @organization,
      year: 2025
    )
    assert submission.valid?
  end

  test "requires year" do
    submission = Submission.new(
      organization: @organization
    )
    assert_not submission.valid?
    assert_includes submission.errors[:year], "can't be blank"
  end

  test "requires organization" do
    submission = Submission.new(
      year: 2025
    )
    assert_not submission.valid?
    assert_includes submission.errors[:organization], "must exist"
  end

  test "year must be a number" do
    submission = Submission.new(
      organization: @organization,
      year: "not a number"
    )
    assert_not submission.valid?
    assert_includes submission.errors[:year], "is not a number"
  end

  test "year must be within reasonable range" do
    # Too old
    submission = Submission.new(
      organization: @organization,
      year: 1999
    )
    assert_not submission.valid?
    assert_includes submission.errors[:year], "must be greater than or equal to 2000"

    # Too future
    submission = Submission.new(
      organization: @organization,
      year: 2100
    )
    assert_not submission.valid?
    assert_includes submission.errors[:year], "must be less than or equal to 2099"
  end

  test "year must be unique per organization" do
    # Create first submission
    Submission.create!(organization: @organization, year: 2025)

    # Duplicate should fail
    duplicate = Submission.new(organization: @organization, year: 2025)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:year], "has already been taken"
  end

  test "same year allowed for different organizations" do
    other_org = organizations(:two)

    # Create submission for org one
    Submission.create!(organization: @organization, year: 2025)

    # Same year for different org should work
    submission = Submission.new(organization: other_org, year: 2025)
    assert submission.valid?
  end

  # === Status Validations ===

  test "status defaults to draft" do
    submission = Submission.new(
      organization: @organization,
      year: 2025
    )
    assert_equal "draft", submission.status
  end

  test "status must be valid" do
    submission = Submission.new(
      organization: @organization,
      year: 2025,
      status: "INVALID"
    )
    assert_not submission.valid?
    assert_includes submission.errors[:status], "is not included in the list"
  end

  test "accepts all valid statuses" do
    %w[draft in_review validated completed].each do |status|
      submission = Submission.new(
        organization: @organization,
        year: 2024 + Submission.count, # Ensure unique year
        status: status
      )
      assert submission.valid?, "Expected status '#{status}' to be valid"
    end
  end

  # === Taxonomy Version ===

  test "taxonomy_version defaults to 2025" do
    submission = Submission.new(
      organization: @organization,
      year: 2025
    )
    assert_equal "2025", submission.taxonomy_version
  end

  # === State Machine ===

  test "can transition from draft to in_review" do
    submission = Submission.create!(organization: @organization, year: 2025)
    assert_equal "draft", submission.status

    submission.start_review!
    assert_equal "in_review", submission.status
  end

  test "can transition from in_review to validated" do
    submission = Submission.create!(
      organization: @organization,
      year: 2025,
      status: "in_review"
    )

    submission.validate_submission!
    assert_equal "validated", submission.status
    assert_not_nil submission.validated_at
  end

  test "can transition from validated to completed" do
    submission = Submission.create!(
      organization: @organization,
      year: 2025,
      status: "validated"
    )

    submission.complete!
    assert_equal "completed", submission.status
    assert_not_nil submission.completed_at
  end

  test "can transition from in_review back to draft on validation failure" do
    submission = Submission.create!(
      organization: @organization,
      year: 2025,
      status: "in_review"
    )

    submission.reject!
    assert_equal "draft", submission.status
  end

  test "cannot transition from draft directly to validated" do
    submission = Submission.create!(organization: @organization, year: 2025)

    assert_raises(Submission::InvalidTransition) do
      submission.validate_submission!
    end
  end

  test "cannot transition from completed to any other status" do
    submission = Submission.create!(
      organization: @organization,
      year: 2025,
      status: "completed",
      completed_at: Time.current
    )

    assert_raises(Submission::InvalidTransition) do
      submission.start_review!
    end
  end

  # === State Predicates ===

  test "draft? returns true for draft submissions" do
    submission = Submission.new(status: "draft")
    assert submission.draft?
  end

  test "in_review? returns true for in_review submissions" do
    submission = Submission.new(status: "in_review")
    assert submission.in_review?
  end

  test "validated? returns true for validated submissions" do
    submission = Submission.new(status: "validated")
    assert submission.validated?
  end

  test "completed? returns true for completed submissions" do
    submission = Submission.new(status: "completed")
    assert submission.completed?
  end

  # === Scopes ===

  test "for_year scope returns submissions for specific year" do
    sub_2030 = Submission.create!(organization: @organization, year: 2030)
    sub_2031 = Submission.create!(organization: organizations(:two), year: 2031)

    results = Submission.for_year(2030)
    assert_includes results, sub_2030
    assert_not_includes results, sub_2031
  end

  test "drafts scope returns only draft submissions" do
    draft = Submission.create!(organization: @organization, year: 2032, status: "draft")
    completed = Submission.create!(
      organization: organizations(:two),
      year: 2032,
      status: "completed",
      completed_at: Time.current
    )

    drafts = Submission.drafts
    assert_includes drafts, draft
    assert_not_includes drafts, completed
  end

  test "completed scope returns only completed submissions" do
    draft = Submission.create!(organization: @organization, year: 2033, status: "draft")
    completed = Submission.create!(
      organization: organizations(:two),
      year: 2033,
      status: "completed",
      completed_at: Time.current
    )

    completed_subs = Submission.completed_submissions
    assert_includes completed_subs, completed
    assert_not_includes completed_subs, draft
  end

  # === Associations ===

  test "belongs to organization" do
    submission = Submission.create!(organization: @organization, year: 2025)
    assert_equal @organization, submission.organization
  end

  test "has many submission_values" do
    submission = Submission.create!(organization: @organization, year: 2025)
    assert_respond_to submission, :submission_values
  end

  test "destroys submission_values when destroyed" do
    submission = submissions(:draft_submission)
    submission_value_count = submission.submission_values.count
    assert submission_value_count > 0, "Test requires submission with values"

    assert_difference "SubmissionValue.count", -submission_value_count do
      submission.destroy
    end
  end

  # === Organization Scoping ===

  test "for_organization scope filters by organization" do
    org_one_submission = Submission.create!(organization: @organization, year: 2034)
    org_two_submission = Submission.create!(organization: organizations(:two), year: 2034)

    results = Submission.for_organization(@organization)
    assert_includes results, org_one_submission
    assert_not_includes results, org_two_submission
  end

  # === Timestamps ===

  test "sets started_at on creation" do
    submission = Submission.create!(organization: @organization, year: 2025)
    assert_not_nil submission.started_at
  end

  test "sets validated_at when validation passes" do
    submission = Submission.create!(
      organization: @organization,
      year: 2025,
      status: "in_review"
    )
    assert_nil submission.validated_at

    submission.validate_submission!
    assert_not_nil submission.validated_at
  end

  test "sets completed_at when completed" do
    submission = Submission.create!(
      organization: @organization,
      year: 2025,
      status: "validated"
    )
    assert_nil submission.completed_at

    submission.complete!
    assert_not_nil submission.completed_at
  end

  # === Downloaded Unvalidated Flag ===

  test "downloaded_unvalidated defaults to false" do
    submission = Submission.new(organization: @organization, year: 2025)
    assert_equal false, submission.downloaded_unvalidated
  end

  test "can mark as downloaded_unvalidated" do
    submission = Submission.create!(organization: @organization, year: 2025)
    submission.update!(downloaded_unvalidated: true)
    assert submission.downloaded_unvalidated
  end

  # === Report Date Helper ===

  test "report_date returns end of year date" do
    submission = Submission.new(year: 2025)
    assert_equal Date.new(2025, 12, 31), submission.report_date
  end

  # === Auditable ===

  test "includes Auditable concern" do
    assert Submission.include?(Auditable)
  end

  test "creates audit log on create" do
    assert_difference "AuditLog.count", 1 do
      Submission.create!(organization: @organization, year: 2025)
    end

    audit_log = AuditLog.last
    assert_equal "create", audit_log.action
    assert_equal "Submission", audit_log.auditable_type
  end

  test "creates audit log on status change" do
    submission = Submission.create!(organization: @organization, year: 2025)

    assert_difference "AuditLog.count", 1 do
      submission.start_review!
    end

    audit_log = AuditLog.last
    assert_equal "update", audit_log.action
    assert_includes audit_log.metadata["changed_fields"], "status"
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert Submission.include?(AmsfConstants)
  end
end
