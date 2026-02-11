# frozen_string_literal: true

require "test_helper"

class Survey::Fields::AuditRound2Test < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "Round 2 Test Account", personal: false)
    @org = Organization.create!(account: @account, name: "Round 2 Agency", rci_number: "R2001")
    @survey = Survey.new(organization: @org, year: 2025)
  end

  # === a1101 — uses clients_kept (non-discarded) ===

  test "a1101 counts only non-discarded clients" do
    c1 = Client.create!(organization: @org, name: "Active", client_type: "NATURAL_PERSON")
    c2 = Client.create!(organization: @org, name: "Discarded", client_type: "NATURAL_PERSON")
    c2.discard

    assert_equal 1, @survey.send(:a1101)
  end

  # === a1102/a1103/a1104 — natural persons only ===

  test "a1102 counts only natural person MC nationals" do
    Client.create!(organization: @org, name: "NP MC", client_type: "NATURAL_PERSON", nationality: "MC")
    Client.create!(organization: @org, name: "LE MC", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", nationality: "MC")

    assert_equal 1, @survey.send(:a1102)
  end

  test "a1103 counts only natural person foreign residents" do
    Client.create!(organization: @org, name: "NP FR Res", client_type: "NATURAL_PERSON", nationality: "FR", residence_status: "RESIDENT")
    Client.create!(organization: @org, name: "LE FR Res", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", nationality: "FR", residence_status: "RESIDENT")

    assert_equal 1, @survey.send(:a1103)
  end

  test "a1104 counts only natural person non-residents" do
    Client.create!(organization: @org, name: "NP NonRes", client_type: "NATURAL_PERSON", residence_status: "NON_RESIDENT")
    Client.create!(organization: @org, name: "LE NonRes", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", residence_status: "NON_RESIDENT")

    assert_equal 1, @survey.send(:a1104)
  end

  # === a1106b — purchase/sale only ===

  test "a1106b excludes rental values" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: client, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 15_000)

    assert_equal 500_000, @survey.send(:a1106b)
  end

  # === a1105w — counts rental months per AMSF definition ===

  test "a1105w counts rental months for qualifying rentals" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE", direction: "WITH_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: client, transaction_type: "RENTAL", direction: "WITH_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 12_000, rental_duration_months: 6)

    # 1 purchase + 6 rental months = 7
    assert_equal 7, @survey.send(:a1105w)
  end

  test "a1105w excludes rental months under 10k" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: client, transaction_type: "RENTAL", direction: "WITH_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 8_000, rental_duration_months: 12)

    assert_equal 0, @survey.send(:a1105w)
  end

  # === a1404b — natural person funds, P&S only ===

  test "a1404b excludes rental values for natural persons" do
    np = Client.create!(organization: @org, name: "NP", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: np, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: np, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 12_000)

    assert_equal 300_000, @survey.send(:a1404b)
  end

  # === a1502b — LE transactions, P&S only (no rental months) ===

  test "a1502b counts only purchase/sale for legal entities" do
    le = Client.create!(organization: @org, name: "SARL", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL")
    Transaction.create!(organization: @org, client: le, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: le, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000, rental_duration_months: 12)

    assert_equal 1, @survey.send(:a1502b)
  end

  # === a1503b — LE funds, P&S only ===

  test "a1503b sums only purchase/sale funds for legal entities" do
    le = Client.create!(organization: @org, name: "SARL", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL")
    Transaction.create!(organization: @org, client: le, transaction_type: "PURCHASE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: le, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 500_000, @survey.send(:a1503b)
  end

  # === a1806tola — trust transactions, P&S only ===

  test "a1806tola counts only purchase/sale for trusts" do
    trust = Client.create!(organization: @org, name: "Trust", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST")
    Transaction.create!(organization: @org, client: trust, transaction_type: "SALE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 1_000_000)
    Transaction.create!(organization: @org, client: trust, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 20_000)

    assert_equal 1, @survey.send(:a1806tola)
  end

  # === a1807tola — trust funds, P&S only ===

  test "a1807tola sums only purchase/sale funds for trusts" do
    trust = Client.create!(organization: @org, name: "Trust", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST")
    Transaction.create!(organization: @org, client: trust, transaction_type: "SALE", direction: "BY_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 1_000_000)
    Transaction.create!(organization: @org, client: trust, transaction_type: "RENTAL", direction: "BY_CLIENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 20_000)

    assert_equal 1_000_000, @survey.send(:a1807tola)
  end

  # === a11304b / a11305b — PEP, P&S only ===

  test "a11304b counts only purchase/sale for PEP clients" do
    pep = Client.create!(organization: @org, name: "PEP", client_type: "NATURAL_PERSON", is_pep: true, pep_type: "DOMESTIC")
    Transaction.create!(organization: @org, client: pep, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: pep, transaction_type: "RENTAL", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 1, @survey.send(:a11304b)
  end

  test "a11305b sums only purchase/sale funds for PEP clients" do
    pep = Client.create!(organization: @org, name: "PEP", client_type: "NATURAL_PERSON", is_pep: true, pep_type: "DOMESTIC")
    Transaction.create!(organization: @org, client: pep, transaction_type: "SALE", transaction_date: Date.new(2025, 3, 1), transaction_value: 800_000)
    Transaction.create!(organization: @org, client: pep, transaction_type: "RENTAL", transaction_date: Date.new(2025, 5, 1), transaction_value: 15_000)

    assert_equal 800_000, @survey.send(:a11305b)
  end

  # === clients_by_sector — MC nationality filter ===

  test "clients_by_sector only counts Monegasque nationals" do
    Client.create!(organization: @org, name: "MC Lawyer", client_type: "NATURAL_PERSON", nationality: "MC", business_sector: "LEGAL_SERVICES")
    Client.create!(organization: @org, name: "FR Lawyer", client_type: "NATURAL_PERSON", nationality: "FR", business_sector: "LEGAL_SERVICES")

    assert_equal 1, @survey.send(:a11502b)
  end

  # === ag24010w / ag24010b — stub returning 0 ===

  test "ag24010w returns 0 until cash_currency is supported" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE", direction: "WITH_CLIENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)

    assert_equal 0, @survey.send(:ag24010w)
  end

  test "ag24010b returns 0 until cash_currency is supported" do
    assert_equal 0, @survey.send(:ag24010b)
  end

  # === air233 — unique clients by nationality ===

  test "air233 groups clients by nationality" do
    Client.create!(organization: @org, name: "MC Client", client_type: "NATURAL_PERSON", nationality: "MC")
    Client.create!(organization: @org, name: "FR Client", client_type: "NATURAL_PERSON", nationality: "FR")
    Client.create!(organization: @org, name: "FR Client 2", client_type: "NATURAL_PERSON", nationality: "FR")

    result = @survey.send(:air233)
    assert_equal 1, result["MC"]
    assert_equal 2, result["FR"]
  end

  test "air233 includes legal entities by incorporation country" do
    Client.create!(organization: @org, name: "MC Company", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", incorporation_country: "MC")

    result = @survey.send(:air233)
    assert_equal 1, result["MC"]
  end

  # === air2313 / air2316 — count properties not clients ===

  test "air2313 counts managed properties with rent >= 10k" do
    client = Client.create!(organization: @org, name: "Landlord", client_type: "NATURAL_PERSON")
    ManagedProperty.create!(organization: @org, client: client, property_address: "1 Rue Grimaldi", management_start_date: Date.new(2024, 1, 1), monthly_rent: 15_000, management_fee_percent: 5)
    ManagedProperty.create!(organization: @org, client: client, property_address: "2 Rue Grimaldi", management_start_date: Date.new(2024, 1, 1), monthly_rent: 8_000, management_fee_percent: 5)

    assert_equal 1, @survey.send(:air2313)
  end

  test "air2316 counts managed properties with rent < 10k" do
    client = Client.create!(organization: @org, name: "Landlord", client_type: "NATURAL_PERSON")
    ManagedProperty.create!(organization: @org, client: client, property_address: "1 Rue Grimaldi", management_start_date: Date.new(2024, 1, 1), monthly_rent: 15_000, management_fee_percent: 5)
    ManagedProperty.create!(organization: @org, client: client, property_address: "2 Rue Grimaldi", management_start_date: Date.new(2024, 1, 1), monthly_rent: 8_000, management_fee_percent: 5)

    assert_equal 1, @survey.send(:air2316)
  end

  test "air2313 excludes properties not active in survey year" do
    client = Client.create!(organization: @org, name: "Landlord", client_type: "NATURAL_PERSON")
    ManagedProperty.create!(organization: @org, client: client, property_address: "Old Prop", management_start_date: Date.new(2020, 1, 1), management_end_date: Date.new(2023, 12, 31), monthly_rent: 15_000, management_fee_percent: 5)

    assert_equal 0, @survey.send(:air2313)
  end

  # === ac1102a — employee count from setting ===

  test "ac1102a returns employee count from setting" do
    assert_equal 0, @survey.send(:ac1102a)
  end

  # === a3307 — setting value ===

  test "a3307 returns setting value defaulting to Non" do
    assert_equal "Non", @survey.send(:a3307)
  end

  # === ac1611 — uses clients_kept ===

  test "ac1611 counts only non-discarded clients" do
    c1 = Client.create!(organization: @org, name: "Active", client_type: "NATURAL_PERSON")
    c2 = Client.create!(organization: @org, name: "Discarded", client_type: "NATURAL_PERSON")
    c2.discard

    assert_equal 1, @survey.send(:ac1611)
  end
end
