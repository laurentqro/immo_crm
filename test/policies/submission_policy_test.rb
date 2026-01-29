# frozen_string_literal: true

require "test_helper"

class SubmissionPolicyTest < ActiveSupport::TestCase
  def setup
    @user_account_user = account_users(:one)
    @other_account_user = account_users(:two)
    @submission = submissions(:draft_submission)
    @completed_submission = submissions(:completed_submission)
    @other_org_submission = submissions(:other_org_submission)
  end

  # Index tests
  test "user can list submissions" do
    policy = SubmissionPolicy.new(@user_account_user, Submission)
    assert policy.index?
  end

  # Show tests
  test "user can view submission in their organization" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert policy.show?
  end

  test "user cannot view submission in another organization" do
    policy = SubmissionPolicy.new(@user_account_user, @other_org_submission)
    assert_not policy.show?
  end

  # Create tests
  test "user can create submission" do
    policy = SubmissionPolicy.new(@user_account_user, Submission.new)
    assert policy.create?
  end

  test "new? delegates to create?" do
    policy = SubmissionPolicy.new(@user_account_user, Submission.new)
    assert policy.new?
  end

  # Update tests
  test "user can update draft submission in their organization" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert policy.update?
  end

  test "user cannot update completed submission" do
    policy = SubmissionPolicy.new(@user_account_user, @completed_submission)
    assert_not policy.update?
  end

  test "user cannot update submission in another organization" do
    policy = SubmissionPolicy.new(@user_account_user, @other_org_submission)
    assert_not policy.update?
  end

  test "edit? delegates to update?" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert policy.edit?
  end

  # Destroy tests
  test "user can destroy submission in their organization" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert policy.destroy?
  end

  test "user cannot destroy submission in another organization" do
    policy = SubmissionPolicy.new(@user_account_user, @other_org_submission)
    assert_not policy.destroy?
  end

  # Review tests
  test "user can review submission in their organization" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert policy.review?
  end

  test "user cannot review submission in another organization" do
    policy = SubmissionPolicy.new(@user_account_user, @other_org_submission)
    assert_not policy.review?
  end

  # Download tests
  test "user can download completed submission in their organization" do
    policy = SubmissionPolicy.new(@user_account_user, @completed_submission)
    assert policy.download?
  end

  test "user cannot download draft submission" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert_not policy.download?
  end

  test "user cannot download submission in another organization" do
    policy = SubmissionPolicy.new(@user_account_user, @other_org_submission)
    assert_not policy.download?
  end

  # Complete tests
  test "user can complete draft submission in their organization" do
    policy = SubmissionPolicy.new(@user_account_user, @submission)
    assert policy.complete?
  end

  test "user cannot complete already completed submission" do
    policy = SubmissionPolicy.new(@user_account_user, @completed_submission)
    assert_not policy.complete?
  end

  test "user cannot complete submission in another organization" do
    policy = SubmissionPolicy.new(@user_account_user, @other_org_submission)
    assert_not policy.complete?
  end

  # Scope tests
  test "scope returns only submissions for current account's organization" do
    scope = SubmissionPolicy::Scope.new(@user_account_user, Submission.all)
    resolved = scope.resolve

    assert resolved.include?(@submission)
    assert resolved.include?(@completed_submission)
    assert_not resolved.include?(@other_org_submission)
  end
end
