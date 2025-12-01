# frozen_string_literal: true

require "test_helper"

class ClientPolicyTest < ActiveSupport::TestCase
  setup do
    @admin_account_user = account_users(:company_admin)
    @regular_account_user = account_users(:company_regular_user)
    @other_admin = account_users(:one)  # Admin on a different account

    @organization = organizations(:company)
    @client = clients(:company_client)
    @other_org_client = clients(:other_org_client)
  end

  # === Index / Scope Tests ===

  test "scope returns only clients for current organization" do
    scope = ClientPolicy::Scope.new(@admin_account_user, Client.all)
    resolved = scope.resolve

    assert resolved.include?(@client)
    assert_not resolved.include?(@other_org_client)
  end

  test "scope excludes discarded clients by default" do
    discarded_client = clients(:discarded_client)
    scope = ClientPolicy::Scope.new(@admin_account_user, Client.all)
    resolved = scope.resolve

    assert_not resolved.include?(discarded_client)
  end

  test "index is permitted for all authenticated users" do
    admin_policy = ClientPolicy.new(@admin_account_user, Client)
    regular_policy = ClientPolicy.new(@regular_account_user, Client)

    assert admin_policy.index?
    assert regular_policy.index?
  end

  # === Show Tests ===

  test "admin can view client in their organization" do
    policy = ClientPolicy.new(@admin_account_user, @client)
    assert policy.show?
  end

  test "regular user can view client in their organization" do
    policy = ClientPolicy.new(@regular_account_user, @client)
    assert policy.show?
  end

  test "admin cannot view client from different organization" do
    policy = ClientPolicy.new(@admin_account_user, @other_org_client)
    assert_not policy.show?
  end

  # === Create Tests ===

  test "admin can create client" do
    policy = ClientPolicy.new(@admin_account_user, Client.new(organization: @organization))
    assert policy.create?
  end

  test "regular user can create client" do
    policy = ClientPolicy.new(@regular_account_user, Client.new(organization: @organization))
    assert policy.create?
  end

  test "new? delegates to create?" do
    policy = ClientPolicy.new(@admin_account_user, Client.new(organization: @organization))
    assert policy.new?
  end

  # === Update Tests ===

  test "admin can update client in their organization" do
    policy = ClientPolicy.new(@admin_account_user, @client)
    assert policy.update?
  end

  test "regular user can update client in their organization" do
    policy = ClientPolicy.new(@regular_account_user, @client)
    assert policy.update?
  end

  test "admin cannot update client from different organization" do
    policy = ClientPolicy.new(@admin_account_user, @other_org_client)
    assert_not policy.update?
  end

  test "edit? delegates to update?" do
    policy = ClientPolicy.new(@admin_account_user, @client)
    assert policy.edit?
  end

  # === Destroy Tests ===

  test "admin can destroy client in their organization" do
    policy = ClientPolicy.new(@admin_account_user, @client)
    assert policy.destroy?
  end

  test "regular user can destroy client in their organization" do
    policy = ClientPolicy.new(@regular_account_user, @client)
    assert policy.destroy?
  end

  test "admin cannot destroy client from different organization" do
    policy = ClientPolicy.new(@admin_account_user, @other_org_client)
    assert_not policy.destroy?
  end

  # === Tenant Isolation Tests ===

  test "policy enforces organization boundary on all actions" do
    cross_tenant_client = @other_org_client
    policy = ClientPolicy.new(@admin_account_user, cross_tenant_client)

    assert_not policy.show?, "Should not show client from different org"
    assert_not policy.update?, "Should not update client from different org"
    assert_not policy.destroy?, "Should not destroy client from different org"
  end

  test "cross-tenant access returns false, not raises" do
    cross_tenant_client = @other_org_client
    policy = ClientPolicy.new(@admin_account_user, cross_tenant_client)

    # Policy methods should return false for cross-tenant, not raise
    # This allows controller to return 404 instead of 403
    assert_nothing_raised { policy.show? }
    assert_nothing_raised { policy.update? }
    assert_nothing_raised { policy.destroy? }
  end

  # === Nil User Handling ===

  test "raises error when account_user is nil" do
    assert_raises Pundit::NotAuthorizedError do
      ClientPolicy.new(nil, @client)
    end
  end

  # === Permission Method Aliases ===

  test "permitted_attributes returns allowed fields" do
    policy = ClientPolicy.new(@admin_account_user, @client)
    attrs = policy.permitted_attributes

    assert_includes attrs, :name
    assert_includes attrs, :client_type
    assert_includes attrs, :nationality
    assert_includes attrs, :residence_country
    assert_includes attrs, :is_pep
    assert_includes attrs, :pep_type
    assert_includes attrs, :risk_level
    assert_includes attrs, :legal_person_type
    assert_includes attrs, :is_vasp
    assert_includes attrs, :vasp_type
    assert_includes attrs, :business_sector
    assert_includes attrs, :became_client_at
    assert_includes attrs, :relationship_ended_at
    assert_includes attrs, :rejection_reason
    assert_includes attrs, :notes

    # Should NOT include protected fields
    assert_not_includes attrs, :organization_id
    assert_not_includes attrs, :deleted_at
  end
end
