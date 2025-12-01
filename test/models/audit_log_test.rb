# frozen_string_literal: true

require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "valid audit log with required attributes" do
    audit_log = audit_logs(:login_event)
    assert audit_log.valid?
  end

  test "organization is optional" do
    audit_log = audit_logs(:failed_login)
    assert audit_log.valid?
    assert_nil audit_log.organization
  end

  test "user is optional" do
    audit_log = AuditLog.new(action: :login)
    assert audit_log.valid?
  end

  test "auditable is optional" do
    audit_log = audit_logs(:login_event)
    assert_nil audit_log.auditable
    assert audit_log.valid?
  end

  # Enum tests - using prefix to avoid AR method conflicts
  test "action enum provides query methods with prefix" do
    login = audit_logs(:login_event)
    assert login.action_login?
    assert_not login.action_logout?
  end

  test "action enum provides class-level scopes with prefix" do
    # Scope methods are action_login, action_logout, etc.
    assert AuditLog.action_login.include?(audit_logs(:login_event))
    assert AuditLog.action_logout.include?(audit_logs(:logout_event))
  end

  test "rejects invalid action values via validation" do
    # With validate: true, Rails enum uses validation instead of raising ArgumentError
    audit_log = AuditLog.new
    audit_log.action = "invalid_action"
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:action], "is not included in the list"
  end

  test "all defined action types are valid" do
    valid_actions = %w[login logout login_failed create update delete download]
    valid_actions.each do |action|
      audit_log = AuditLog.new(action: action)
      assert audit_log.valid?, "Expected action '#{action}' to be valid"
    end
  end

  # Metadata validation tests
  test "allows valid metadata keys" do
    audit_log = AuditLog.new(
      action: :login,
      metadata: {
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0",
        changed_fields: ["name", "email"]
      }
    )
    assert audit_log.valid?
  end

  test "rejects invalid metadata keys" do
    audit_log = AuditLog.new(
      action: :login,
      metadata: {
        ip_address: "192.168.1.1",
        hacker_data: "malicious"
      }
    )
    assert_not audit_log.valid?
    assert_includes audit_log.errors[:metadata].first, "hacker_data"
  end

  test "allows empty metadata" do
    audit_log = AuditLog.new(action: :login, metadata: {})
    assert audit_log.valid?
  end

  test "allows nil metadata" do
    audit_log = AuditLog.new(action: :login, metadata: nil)
    assert audit_log.valid?
  end

  # Metadata value type validation tests
  test "rejects ip_address longer than 45 chars" do
    audit_log = AuditLog.new(
      action: :login,
      metadata: { "ip_address" => "a" * 46 }
    )
    assert_not audit_log.valid?
    assert audit_log.errors[:metadata].any? { |e| e.include?("ip_address") }
  end

  test "rejects user_agent longer than 500 chars" do
    audit_log = AuditLog.new(
      action: :login,
      metadata: { "user_agent" => "a" * 501 }
    )
    assert_not audit_log.valid?
    assert audit_log.errors[:metadata].any? { |e| e.include?("user_agent") }
  end

  test "rejects non-array changed_fields" do
    audit_log = AuditLog.new(
      action: :update,
      metadata: { "changed_fields" => "not_an_array" }
    )
    assert_not audit_log.valid?
    assert audit_log.errors[:metadata].any? { |e| e.include?("changed_fields") }
  end

  test "rejects changed_fields with non-string elements" do
    audit_log = AuditLog.new(
      action: :update,
      metadata: { "changed_fields" => ["valid", 123, "also_valid"] }
    )
    assert_not audit_log.valid?
    assert audit_log.errors[:metadata].any? { |e| e.include?("changed_fields") }
  end

  test "allows valid metadata value types" do
    audit_log = AuditLog.new(
      action: :update,
      metadata: {
        "ip_address" => "192.168.1.1",
        "user_agent" => "Mozilla/5.0 (compatible)",
        "changed_fields" => ["name", "email", "phone"]
      }
    )
    assert audit_log.valid?
  end

  # Scope tests
  test "for_organization scope filters by organization" do
    org_one = organizations(:one)
    logs = AuditLog.for_organization(org_one)
    assert logs.include?(audit_logs(:login_event))
    assert_not logs.include?(audit_logs(:failed_login))
  end

  test "for_user scope filters by user" do
    user = users(:one)
    logs = AuditLog.for_user(user)
    assert logs.include?(audit_logs(:login_event))
  end

  test "recent scope orders by created_at desc" do
    recent_logs = AuditLog.recent.limit(2)
    if recent_logs.count >= 2
      assert recent_logs.first.created_at >= recent_logs.second.created_at
    end
  end

  test "auth_events scope returns authentication actions" do
    auth_logs = AuditLog.auth_events
    assert auth_logs.include?(audit_logs(:login_event))
    assert auth_logs.include?(audit_logs(:logout_event))
    assert auth_logs.include?(audit_logs(:failed_login))
    assert_not auth_logs.include?(audit_logs(:create_event))
  end

  test "data_events scope returns data modification actions" do
    data_logs = AuditLog.data_events
    assert data_logs.include?(audit_logs(:create_event))
    assert data_logs.include?(audit_logs(:update_event))
    assert_not data_logs.include?(audit_logs(:login_event))
  end

  test "older_than scope filters by date" do
    # Create an old log for testing
    old_log = AuditLog.create!(
      action: :login,
      created_at: 6.years.ago
    )

    old_logs = AuditLog.older_than(5.years.ago)
    assert old_logs.include?(old_log)
    assert_not old_logs.include?(audit_logs(:login_event))
  end

  # Association tests
  test "belongs to organization" do
    audit_log = audit_logs(:login_event)
    assert_equal organizations(:one), audit_log.organization
  end

  test "belongs to user" do
    audit_log = audit_logs(:login_event)
    assert_equal users(:one), audit_log.user
  end

  test "includes AmsfConstants" do
    assert AuditLog.include?(AmsfConstants)
  end
end
