# frozen_string_literal: true

require "test_helper"

class StrReportTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @transaction = transactions(:purchase)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid str_report with required attributes" do
    str_report = StrReport.new(
      organization: @organization,
      report_date: Date.current,
      reason: "CASH"
    )
    assert str_report.valid?
  end

  test "requires organization" do
    str_report = StrReport.new(
      report_date: Date.current,
      reason: "CASH"
    )
    assert_not str_report.valid?
    assert_includes str_report.errors[:organization], "must exist"
  end

  test "requires report_date" do
    str_report = StrReport.new(
      organization: @organization,
      reason: "CASH"
    )
    assert_not str_report.valid?
    assert_includes str_report.errors[:report_date], "can't be blank"
  end

  test "requires reason" do
    str_report = StrReport.new(
      organization: @organization,
      report_date: Date.current
    )
    assert_not str_report.valid?
    assert_includes str_report.errors[:reason], "can't be blank"
  end

  test "reason must be valid" do
    str_report = StrReport.new(
      organization: @organization,
      report_date: Date.current,
      reason: "INVALID"
    )
    assert_not str_report.valid?
    assert_includes str_report.errors[:reason], "is not included in the list"
  end

  test "accepts all valid reasons" do
    %w[CASH PEP UNUSUAL_PATTERN OTHER].each do |reason|
      str_report = StrReport.new(
        organization: @organization,
        report_date: Date.current,
        reason: reason
      )
      assert str_report.valid?, "Expected reason '#{reason}' to be valid"
    end
  end

  # === Optional Associations ===

  test "client is optional" do
    str_report = StrReport.new(
      organization: @organization,
      report_date: Date.current,
      reason: "UNUSUAL_PATTERN"
    )
    assert str_report.valid?
    assert_nil str_report.client
  end

  test "accepts client association" do
    str_report = StrReport.new(
      organization: @organization,
      client: @client,
      report_date: Date.current,
      reason: "PEP"
    )
    assert str_report.valid?
    assert_equal @client, str_report.client
  end

  test "linked_transaction is optional" do
    str_report = StrReport.new(
      organization: @organization,
      report_date: Date.current,
      reason: "UNUSUAL_PATTERN"
    )
    assert str_report.valid?
    assert_nil str_report.linked_transaction
  end

  test "accepts linked_transaction association" do
    str_report = StrReport.new(
      organization: @organization,
      linked_transaction: @transaction,
      report_date: Date.current,
      reason: "CASH"
    )
    assert str_report.valid?
    assert_equal @transaction, str_report.linked_transaction
  end

  # === Scopes ===

  test "for_year scope filters by year" do
    this_year = str_reports(:this_year_str)
    last_year = str_reports(:last_year_str)

    current_year_reports = StrReport.for_year(Date.current.year)
    assert_includes current_year_reports, this_year
    assert_not_includes current_year_reports, last_year
  end

  test "by_reason scope filters by reason" do
    cash_report = str_reports(:cash_str)
    pep_report = str_reports(:pep_str)

    cash_reports = StrReport.by_reason("CASH")
    assert_includes cash_reports, cash_report
    assert_not_includes cash_reports, pep_report
  end

  test "with_client scope returns reports with client" do
    with_client = str_reports(:str_with_client)
    without_client = str_reports(:str_without_client)

    reports_with_client = StrReport.with_client
    assert_includes reports_with_client, with_client
    assert_not_includes reports_with_client, without_client
  end

  test "with_transaction scope returns reports with transaction" do
    with_transaction = str_reports(:str_with_transaction)
    without_transaction = str_reports(:str_without_transaction)

    reports_with_transaction = StrReport.with_transaction
    assert_includes reports_with_transaction, with_transaction
    assert_not_includes reports_with_transaction, without_transaction
  end

  test "recent scope orders by report_date descending" do
    reports = StrReport.recent
    assert reports.first.report_date >= reports.last.report_date
  end

  # === Soft Delete (Discard) ===

  test "soft deletes str_report with discard" do
    str_report = str_reports(:this_year_str)
    assert_nil str_report.deleted_at

    str_report.discard
    assert_not_nil str_report.deleted_at
    assert str_report.discarded?
  end

  test "kept scope excludes discarded str_reports" do
    str_report = str_reports(:this_year_str)
    str_report.discard

    assert_not_includes StrReport.kept, str_report
  end

  test "undiscard restores soft-deleted str_report" do
    str_report = str_reports(:this_year_str)
    str_report.discard
    assert str_report.discarded?

    str_report.undiscard
    assert_not str_report.discarded?
    assert_nil str_report.deleted_at
  end

  # === Associations ===

  test "belongs to organization" do
    str_report = str_reports(:this_year_str)
    assert_equal @organization, str_report.organization
  end

  test "can belong to client" do
    str_report = str_reports(:str_with_client)
    assert_not_nil str_report.client
  end

  test "can belong to linked_transaction" do
    str_report = str_reports(:str_with_transaction)
    assert_not_nil str_report.linked_transaction
  end

  # === Organization Scoping ===

  test "for_organization scope filters by organization" do
    org_one_report = str_reports(:this_year_str)
    org_two_report = str_reports(:other_org_str)

    org_one_reports = StrReport.for_organization(@organization)
    assert_includes org_one_reports, org_one_report
    assert_not_includes org_one_reports, org_two_report
  end

  # === Instance Methods ===

  test "reason_label returns human-readable label" do
    assert_equal "Cash Payment", str_reports(:cash_str).reason_label
    assert_equal "PEP Involvement", str_reports(:pep_str).reason_label
    assert_equal "Unusual Pattern", str_reports(:unusual_pattern_str).reason_label
    assert_equal "Other", str_reports(:other_str).reason_label
  end

  # === Auditable ===

  test "includes Auditable concern" do
    assert StrReport.include?(Auditable)
  end

  test "creates audit log on create" do
    assert_difference "AuditLog.count", 1 do
      StrReport.create!(
        organization: @organization,
        report_date: Date.current,
        reason: "CASH"
      )
    end

    audit_log = AuditLog.last
    assert_equal "create", audit_log.action
    assert_equal "StrReport", audit_log.auditable_type
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert StrReport.include?(AmsfConstants)
  end
end
