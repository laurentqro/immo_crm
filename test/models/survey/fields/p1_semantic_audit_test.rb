# frozen_string_literal: true

require "test_helper"

class Survey::Fields::P1SemanticAuditTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "P1 Audit Account", personal: false)
    @org = Organization.create!(account: @account, name: "P1 Audit Agency", rci_number: "P1001")
    @survey = Survey.new(organization: @org, year: 2025)
  end

  # ==========================================================================
  # Q37 (aMLES) — Monaco legal entities grouped by type
  # ==========================================================================

  test "amles returns empty hash when no MC legal entities" do
    assert_equal({}, @survey.send(:amles))
  end

  test "amles groups MC legal entities by type" do
    Client.create!(organization: @org, name: "SCI Alpha", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "MC")
    Client.create!(organization: @org, name: "SCI Beta", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "MC")
    Client.create!(organization: @org, name: "SAM Gamma", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SAM", incorporation_country: "MC")

    result = @survey.send(:amles)
    assert_equal 2, result["SCI"]
    assert_equal 1, result["SAM"]
  end

  test "amles excludes non-MC legal entities" do
    Client.create!(organization: @org, name: "FR Corp", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "FR")
    Client.create!(organization: @org, name: "MC Corp", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "MC")

    result = @survey.send(:amles)
    assert_equal({"SARL" => 1}, result)
  end

  test "amles excludes natural persons" do
    Client.create!(organization: @org, name: "Person", client_type: "NATURAL_PERSON",
      nationality: "MC")
    assert_equal({}, @survey.send(:amles))
  end

  test "amles excludes soft-deleted clients" do
    Client.create!(organization: @org, name: "Deleted SCI", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "MC", deleted_at: Time.current)
    assert_equal({}, @survey.send(:amles))
  end

  # ==========================================================================
  # Q80 (aC171) — MC nationals with purchase/sale transactions
  # ==========================================================================

  test "ac171 returns Non when no MC nationals with purchases/sales" do
    assert_equal "Non", @survey.send(:ac171)
  end

  test "ac171 returns Oui when MC national has purchase transaction" do
    client = Client.create!(organization: @org, name: "MC Buyer", client_type: "NATURAL_PERSON",
      nationality: "MC")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)

    assert_equal "Oui", @survey.send(:ac171)
  end

  test "ac171 returns Oui when MC national has sale transaction" do
    client = Client.create!(organization: @org, name: "MC Seller", client_type: "NATURAL_PERSON",
      nationality: "MC")
    Transaction.create!(organization: @org, client: client, transaction_type: "SALE",
      transaction_date: Date.new(2025, 3, 1), transaction_value: 300_000)

    assert_equal "Oui", @survey.send(:ac171)
  end

  test "ac171 returns Non for MC nationals with only rental transactions" do
    client = Client.create!(organization: @org, name: "MC Renter", client_type: "NATURAL_PERSON",
      nationality: "MC")
    Transaction.create!(organization: @org, client: client, transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 6, 1), transaction_value: 15_000)

    assert_equal "Non", @survey.send(:ac171)
  end

  test "ac171 returns Non for non-MC nationals with purchases" do
    client = Client.create!(organization: @org, name: "FR Buyer", client_type: "NATURAL_PERSON",
      nationality: "FR")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)

    assert_equal "Non", @survey.send(:ac171)
  end

  test "ac171 excludes transactions outside reporting year" do
    client = Client.create!(organization: @org, name: "MC Buyer", client_type: "NATURAL_PERSON",
      nationality: "MC")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(2024, 12, 31), transaction_value: 500_000)

    assert_equal "Non", @survey.send(:ac171)
  end

  # ==========================================================================
  # Q208-Q210 (a3401, a3402, a3403) — Prospect rejections
  # ==========================================================================

  test "a3401 returns 0 when no rejected prospects" do
    assert_equal 0, @survey.send(:a3401)
  end

  test "a3401 counts rejected prospects in the year" do
    Client.create!(organization: @org, name: "Rejected 1", client_type: "NATURAL_PERSON",
      rejection_reason: "AML_CFT", became_client_at: DateTime.new(2025, 3, 15))
    Client.create!(organization: @org, name: "Rejected 2", client_type: "NATURAL_PERSON",
      rejection_reason: "OTHER", became_client_at: DateTime.new(2025, 6, 1))

    assert_equal 2, @survey.send(:a3401)
  end

  test "a3401 excludes rejections from other years" do
    Client.create!(organization: @org, name: "Old Reject", client_type: "NATURAL_PERSON",
      rejection_reason: "AML_CFT", became_client_at: DateTime.new(2024, 12, 31))

    assert_equal 0, @survey.send(:a3401)
  end

  test "a3402 returns Oui by default" do
    assert_equal "Oui", @survey.send(:a3402)
  end

  test "a3403 counts AML_CFT rejections specifically" do
    Client.create!(organization: @org, name: "AML Reject", client_type: "NATURAL_PERSON",
      rejection_reason: "AML_CFT", became_client_at: DateTime.new(2025, 3, 15))
    Client.create!(organization: @org, name: "Other Reject", client_type: "NATURAL_PERSON",
      rejection_reason: "OTHER", became_client_at: DateTime.new(2025, 6, 1))

    assert_equal 1, @survey.send(:a3403)
  end

  test "a3403 returns 0 when no AML rejections" do
    assert_equal 0, @survey.send(:a3403)
  end

  # ==========================================================================
  # Q211-Q213 (a3414, a3415, a3416) — Terminated relationships
  # ==========================================================================

  test "a3414 returns 0 when no terminated relationships" do
    assert_equal 0, @survey.send(:a3414)
  end

  test "a3414 counts terminated relationships in the year" do
    Client.create!(organization: @org, name: "Terminated 1", client_type: "NATURAL_PERSON",
      relationship_end_reason: "AML_CONCERN", relationship_ended_at: DateTime.new(2025, 4, 1))
    Client.create!(organization: @org, name: "Terminated 2", client_type: "NATURAL_PERSON",
      relationship_end_reason: "BUSINESS_DECISION", relationship_ended_at: DateTime.new(2025, 7, 1))

    assert_equal 2, @survey.send(:a3414)
  end

  test "a3414 excludes terminations from other years" do
    Client.create!(organization: @org, name: "Old Term", client_type: "NATURAL_PERSON",
      relationship_end_reason: "AML_CONCERN", relationship_ended_at: DateTime.new(2024, 11, 1))

    assert_equal 0, @survey.send(:a3414)
  end

  test "a3415 returns Oui by default" do
    assert_equal "Oui", @survey.send(:a3415)
  end

  test "a3416 counts AML_CONCERN terminations specifically" do
    Client.create!(organization: @org, name: "AML Term", client_type: "NATURAL_PERSON",
      relationship_end_reason: "AML_CONCERN", relationship_ended_at: DateTime.new(2025, 5, 1))
    Client.create!(organization: @org, name: "Biz Term", client_type: "NATURAL_PERSON",
      relationship_end_reason: "BUSINESS_DECISION", relationship_ended_at: DateTime.new(2025, 6, 1))

    assert_equal 1, @survey.send(:a3416)
  end

  test "a3416 returns 0 when no AML terminations" do
    assert_equal 0, @survey.send(:a3416)
  end

  # ==========================================================================
  # C67-C69 (aC1701, aC1702, aC1703) — Enhanced due diligence counts
  # ==========================================================================

  test "ac1701 returns 0 when no reinforced DD clients" do
    assert_equal 0, @survey.send(:ac1701)
  end

  test "ac1701 counts reinforced DD clients onboarded in reporting year" do
    Client.create!(organization: @org, name: "EDD Client", client_type: "NATURAL_PERSON",
      due_diligence_level: "REINFORCED", became_client_at: DateTime.new(2025, 2, 1))
    Client.create!(organization: @org, name: "Standard Client", client_type: "NATURAL_PERSON",
      due_diligence_level: "STANDARD", became_client_at: DateTime.new(2025, 3, 1))

    assert_equal 1, @survey.send(:ac1701)
  end

  test "ac1701 excludes reinforced DD clients onboarded outside year" do
    Client.create!(organization: @org, name: "Old EDD", client_type: "NATURAL_PERSON",
      due_diligence_level: "REINFORCED", became_client_at: DateTime.new(2024, 6, 1))

    assert_equal 0, @survey.send(:ac1701)
  end

  test "ac1702 counts all reinforced DD clients" do
    Client.create!(organization: @org, name: "EDD 1", client_type: "NATURAL_PERSON",
      due_diligence_level: "REINFORCED")
    Client.create!(organization: @org, name: "EDD 2", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", due_diligence_level: "REINFORCED")
    Client.create!(organization: @org, name: "Standard", client_type: "NATURAL_PERSON",
      due_diligence_level: "STANDARD")

    assert_equal 2, @survey.send(:ac1702)
  end

  test "ac1703 returns 0 when no clients" do
    assert_equal 0, @survey.send(:ac1703)
  end

  test "ac1703 returns percentage of reinforced DD clients" do
    Client.create!(organization: @org, name: "EDD", client_type: "NATURAL_PERSON",
      due_diligence_level: "REINFORCED")
    Client.create!(organization: @org, name: "Standard 1", client_type: "NATURAL_PERSON",
      due_diligence_level: "STANDARD")
    Client.create!(organization: @org, name: "Standard 2", client_type: "NATURAL_PERSON",
      due_diligence_level: "STANDARD")
    Client.create!(organization: @org, name: "Standard 3", client_type: "NATURAL_PERSON",
      due_diligence_level: "STANDARD")

    # 1 out of 4 = 25%
    assert_equal 25.0, @survey.send(:ac1703)
  end

  # ==========================================================================
  # Q214-Q215 (a3701A, a3701) — Section 3 comments
  # ==========================================================================

  test "a3701a returns Non when no section 3 comment setting" do
    assert_equal "Non", @survey.send(:a3701a)
  end

  test "a3701a returns Oui when section 3 comment setting present" do
    Setting.create!(organization: @org, category: "controls", key: "a3701a", value: "Some comment")
    assert_equal "Oui", @survey.send(:a3701a)
  end

  test "a3701 returns nil when no comment" do
    assert_nil @survey.send(:a3701)
  end

  test "a3701 returns comment text" do
    Setting.create!(organization: @org, category: "controls", key: "a3701", value: "Section 3 feedback")
    assert_equal "Section 3 feedback", @survey.send(:a3701)
  end

  # ==========================================================================
  # C104-C105 (aC116A, aC11601) — Controls comments
  # ==========================================================================

  test "ac116a returns Non when no controls comment setting" do
    assert_equal "Non", @survey.send(:ac116a)
  end

  test "ac116a returns Oui when controls comment setting present" do
    Setting.create!(organization: @org, category: "controls", key: "ac116a", value: "Controls feedback")
    assert_equal "Oui", @survey.send(:ac116a)
  end

  test "ac11601 returns controls comment text" do
    Setting.create!(organization: @org, category: "controls", key: "ac11601", value: "My controls comment")
    assert_equal "My controls comment", @survey.send(:ac11601)
  end

  # ==========================================================================
  # Q162 (aIR234) — Unique rental properties
  # ==========================================================================

  test "air234 returns 0 when no managed properties" do
    assert_equal 0, @survey.send(:air234)
  end

  test "air234 counts managed properties active in reporting year" do
    client = Client.create!(organization: @org, name: "Landlord", client_type: "NATURAL_PERSON")

    ManagedProperty.create!(organization: @org, client: client,
      property_address: "1 Rue Test", management_start_date: Date.new(2024, 1, 1),
      monthly_rent: 12_000, management_fee_percent: 5)
    ManagedProperty.create!(organization: @org, client: client,
      property_address: "2 Rue Test", management_start_date: Date.new(2025, 6, 1),
      monthly_rent: 15_000, management_fee_percent: 5)

    assert_equal 2, @survey.send(:air234)
  end

  test "air234 excludes properties ended before reporting year" do
    client = Client.create!(organization: @org, name: "Landlord", client_type: "NATURAL_PERSON")

    ManagedProperty.create!(organization: @org, client: client,
      property_address: "Old Property", management_start_date: Date.new(2020, 1, 1),
      management_end_date: Date.new(2024, 12, 31),
      monthly_rent: 12_000, management_fee_percent: 5)

    assert_equal 0, @survey.send(:air234)
  end

  test "air234 excludes properties starting after reporting year" do
    client = Client.create!(organization: @org, name: "Landlord", client_type: "NATURAL_PERSON")

    ManagedProperty.create!(organization: @org, client: client,
      property_address: "Future Property", management_start_date: Date.new(2026, 1, 1),
      monthly_rent: 12_000, management_fee_percent: 5)

    assert_equal 0, @survey.send(:air234)
  end
end
