# frozen_string_literal: true

require "test_helper"

class OrganizationPolicyTest < ActiveSupport::TestCase
  def setup
    @admin_account_user = account_users(:company_admin)
    @regular_account_user = account_users(:company_regular_user)
    @other_admin = account_users(:one)  # Admin on a different account
    @organization = organizations(:company)
    @other_organization = organizations(:one)
  end

  # Show tests
  test "admin can view their own organization" do
    policy = OrganizationPolicy.new(@admin_account_user, @organization)
    assert policy.show?
  end

  test "regular user can view their own organization" do
    policy = OrganizationPolicy.new(@regular_account_user, @organization)
    assert policy.show?
  end

  test "admin cannot view another account's organization" do
    policy = OrganizationPolicy.new(@admin_account_user, @other_organization)
    assert_not policy.show?
  end

  # Update tests
  test "admin can update their own organization" do
    policy = OrganizationPolicy.new(@admin_account_user, @organization)
    assert policy.update?
  end

  test "regular user cannot update organization" do
    policy = OrganizationPolicy.new(@regular_account_user, @organization)
    assert_not policy.update?
  end

  test "admin cannot update another account's organization" do
    policy = OrganizationPolicy.new(@admin_account_user, @other_organization)
    assert_not policy.update?
  end

  test "edit? delegates to update?" do
    admin_policy = OrganizationPolicy.new(@admin_account_user, @organization)
    regular_policy = OrganizationPolicy.new(@regular_account_user, @organization)

    assert admin_policy.edit?
    assert_not regular_policy.edit?
  end

  # Create tests
  test "admin can create organization" do
    policy = OrganizationPolicy.new(@admin_account_user, Organization.new)
    assert policy.create?
  end

  test "regular user cannot create organization" do
    policy = OrganizationPolicy.new(@regular_account_user, Organization.new)
    assert_not policy.create?
  end

  test "new? delegates to create?" do
    admin_policy = OrganizationPolicy.new(@admin_account_user, Organization.new)
    regular_policy = OrganizationPolicy.new(@regular_account_user, Organization.new)

    assert admin_policy.new?
    assert_not regular_policy.new?
  end

  # Destroy tests
  test "destroy is never permitted" do
    admin_policy = OrganizationPolicy.new(@admin_account_user, @organization)
    regular_policy = OrganizationPolicy.new(@regular_account_user, @organization)

    assert_not admin_policy.destroy?
    assert_not regular_policy.destroy?
  end

  # Scope tests
  test "scope returns only organizations for current account" do
    scope = OrganizationPolicy::Scope.new(@admin_account_user, Organization.all)
    resolved = scope.resolve

    assert resolved.include?(@organization)
    assert_not resolved.include?(@other_organization)
  end

  # Authorization without account_user
  test "raises error when account_user is nil" do
    assert_raises Pundit::NotAuthorizedError do
      OrganizationPolicy.new(nil, @organization)
    end
  end
end
