# frozen_string_literal: true

require "test_helper"

class Survey::Fields::FiveYearLookbackTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "Lookback Test Account", personal: false)
    @org = Organization.create!(account: @account, name: "Lookback Test Agency", rci_number: "LBK001")
    @survey = Survey.new(organization: @org, year: 2025)

    @french_np = Client.create!(organization: @org, name: "French Buyer", client_type: "NATURAL_PERSON", nationality: "FR")
    @italian_np = Client.create!(organization: @org, name: "Italian Buyer", client_type: "NATURAL_PERSON", nationality: "IT")
    @monaco_le = Client.create!(organization: @org, name: "Monaco SCI", client_type: "LEGAL_ENTITY", legal_entity_type: "SCI", incorporation_country: "MC")
  end

  # === Q155: air237b — 5-year transaction count by nationality ===

  test "air237b returns empty hash when no transactions exist" do
    assert_equal({}, @survey.send(:air237b))
  end

  test "air237b counts purchase/sale transactions grouped by client nationality" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "SALE", transaction_date: Date.new(2025, 6, 1), transaction_value: 600_000)
    Transaction.create!(organization: @org, client: @italian_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 4, 1), transaction_value: 400_000)

    result = @survey.send(:air237b)
    assert_equal 2, result["FR"]
    assert_equal 1, result["IT"]
  end

  test "air237b includes transactions from 4 previous years" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2021, 6, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "SALE", transaction_date: Date.new(2023, 6, 1), transaction_value: 400_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)

    result = @survey.send(:air237b)
    assert_equal 3, result["FR"]
  end

  test "air237b excludes transactions older than 5 years" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2020, 12, 31), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2021, 1, 1), transaction_value: 400_000)

    result = @survey.send(:air237b)
    assert_equal 1, result["FR"]
  end

  test "air237b excludes rental transactions" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "RENTAL", transaction_date: Date.new(2025, 3, 1), transaction_value: 15_000)

    assert_equal({}, @survey.send(:air237b))
  end

  test "air237b merges natural person nationality and legal entity incorporation country" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: @monaco_le, transaction_type: "SALE", transaction_date: Date.new(2025, 4, 1), transaction_value: 800_000)

    result = @survey.send(:air237b)
    assert_equal 1, result["FR"]
    assert_equal 1, result["MC"]
  end

  test "air237b merges counts when NP nationality matches LE incorporation country" do
    french_le = Client.create!(organization: @org, name: "French SARL", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", incorporation_country: "FR")

    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: french_le, transaction_type: "SALE", transaction_date: Date.new(2025, 4, 1), transaction_value: 600_000)

    result = @survey.send(:air237b)
    assert_equal 2, result["FR"]
  end

  # === Q156: air238b — Current year funds by nationality ===

  test "air238b returns empty hash when no transactions exist" do
    assert_equal({}, @survey.send(:air238b))
  end

  test "air238b sums purchase/sale values for current year by nationality" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "SALE", transaction_date: Date.new(2025, 6, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: @italian_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 4, 1), transaction_value: 400_000)

    result = @survey.send(:air238b)
    assert_equal 800_000, result["FR"]
    assert_equal 400_000, result["IT"]
  end

  test "air238b excludes transactions from other years" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2024, 12, 31), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 1, 1), transaction_value: 300_000)

    result = @survey.send(:air238b)
    assert_equal 300_000, result["FR"]
  end

  test "air238b excludes rental transactions" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "RENTAL", transaction_date: Date.new(2025, 3, 1), transaction_value: 15_000)

    assert_equal({}, @survey.send(:air238b))
  end

  # === Q157: air239b — 5-year funds by nationality ===

  test "air239b returns empty hash when no transactions exist" do
    assert_equal({}, @survey.send(:air239b))
  end

  test "air239b sums purchase/sale values over 5 years by nationality" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2021, 3, 1), transaction_value: 200_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "SALE", transaction_date: Date.new(2023, 6, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)

    result = @survey.send(:air239b)
    assert_equal 1_000_000, result["FR"]
  end

  test "air239b excludes transactions older than 5 years" do
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2020, 12, 31), transaction_value: 999_999)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2021, 1, 1), transaction_value: 100_000)

    result = @survey.send(:air239b)
    assert_equal 100_000, result["FR"]
  end

  # === Helper: five_year_transactions ===

  test "five_year_transactions includes exactly years year-4 through year" do
    # year = 2025, so range is 2021-01-01 to 2025-12-31
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2020, 12, 31), transaction_value: 100)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2021, 1, 1), transaction_value: 200)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2025, 12, 31), transaction_value: 300)
    Transaction.create!(organization: @org, client: @french_np, transaction_type: "PURCHASE", transaction_date: Date.new(2026, 1, 1), transaction_value: 400)

    assert_equal 2, @survey.send(:five_year_transactions).count
  end
end
