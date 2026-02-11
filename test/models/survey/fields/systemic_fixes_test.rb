# frozen_string_literal: true

require "test_helper"

class Survey::Fields::SystemicFixesTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "Systemic Test Account", personal: false)
    @org = Organization.create!(account: @account, name: "Systemic Test Agency", rci_number: "SYS001")
    @survey = Survey.new(organization: @org, year: 2025)
  end

  # === clients_by_sector — MC nationality filter (Q81-Q109) ===

  test "clients_by_sector only counts Monegasque nationals" do
    Client.create!(organization: @org, name: "MC Lawyer", client_type: "NATURAL_PERSON", nationality: "MC", business_sector: "LEGAL_SERVICES")
    Client.create!(organization: @org, name: "FR Lawyer", client_type: "NATURAL_PERSON", nationality: "FR", business_sector: "LEGAL_SERVICES")

    assert_equal 1, @survey.send(:a11502b)
  end

  test "clients_by_sector returns 0 when no MC nationals in sector" do
    Client.create!(organization: @org, name: "FR Accountant", client_type: "NATURAL_PERSON", nationality: "FR", business_sector: "ACCOUNTING")

    assert_equal 0, @survey.send(:a11602b)
  end

  # === a1102/a1103/a1104 — natural persons filter (Q23-Q25) ===

  test "a1102 counts only natural person MC nationals" do
    Client.create!(organization: @org, name: "NP MC", client_type: "NATURAL_PERSON", nationality: "MC")
    Client.create!(organization: @org, name: "LE MC", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", nationality: "MC")

    assert_equal 1, @survey.send(:a1102)
  end

  test "a1103 counts only natural person foreign residents" do
    Client.create!(organization: @org, name: "NP FR Resident", client_type: "NATURAL_PERSON", nationality: "FR", residence_status: "RESIDENT")
    Client.create!(organization: @org, name: "LE FR Resident", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", nationality: "FR", residence_status: "RESIDENT")

    assert_equal 1, @survey.send(:a1103)
  end

  test "a1104 counts only natural person non-residents" do
    Client.create!(organization: @org, name: "NP Non-Res", client_type: "NATURAL_PERSON", residence_status: "NON_RESIDENT")
    Client.create!(organization: @org, name: "LE Non-Res", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", residence_status: "NON_RESIDENT")

    assert_equal 1, @survey.send(:a1104)
  end

  # === a1106b — purchase/sale only filter (Q6) ===

  test "a1106b excludes rental transaction values" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: client, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 15_000)

    assert_equal 500_000, @survey.send(:a1106b)
  end

  # === a1404b — natural person funds, purchase/sale only (Q28) ===

  test "a1404b excludes rental values for natural persons" do
    np = Client.create!(organization: @org, name: "NP", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: np, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: np, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 12_000)

    assert_equal 300_000, @survey.send(:a1404b)
  end

  # === a1502b — LE transactions, purchase/sale only (Q34) ===

  test "a1502b counts only purchase/sale transactions for legal entities" do
    le = Client.create!(organization: @org, name: "SARL", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL")
    Transaction.create!(organization: @org, client: le, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: le, transaction_type: "SALE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 600_000)
    Transaction.create!(organization: @org, client: le, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 2, @survey.send(:a1502b)
  end

  # === a1503b — LE funds, purchase/sale only (Q35) ===

  test "a1503b sums only purchase/sale funds for legal entities" do
    le = Client.create!(organization: @org, name: "SARL", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL")
    Transaction.create!(organization: @org, client: le, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: le, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 500_000, @survey.send(:a1503b)
  end

  # === a1806tola — trust transactions, purchase/sale only (Q46) ===

  test "a1806tola counts only purchase/sale transactions for trusts" do
    trust = Client.create!(organization: @org, name: "Trust", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST")
    Transaction.create!(organization: @org, client: trust, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: trust, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 1, @survey.send(:a1806tola)
  end

  # === a11304b — PEP transactions, purchase/sale only (Q52) ===

  test "a11304b counts only purchase/sale transactions for PEP clients" do
    pep = Client.create!(organization: @org, name: "PEP", client_type: "NATURAL_PERSON", is_pep: true, pep_type: "DOMESTIC")
    Transaction.create!(organization: @org, client: pep, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: pep, transaction_type: "RENTAL", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 1, @survey.send(:a11304b)
  end

  # === a11305b — PEP funds, purchase/sale only (Q53) ===

  test "a11305b sums only purchase/sale funds for PEP clients" do
    pep = Client.create!(organization: @org, name: "PEP", client_type: "NATURAL_PERSON", is_pep: true, pep_type: "DOMESTIC")
    Transaction.create!(organization: @org, client: pep, transaction_type: "SALE", transaction_date: Date.new(2025, 3, 1), transaction_value: 800_000)
    Transaction.create!(organization: @org, client: pep, transaction_type: "RENTAL", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 800_000, @survey.send(:a11305b)
  end
end
