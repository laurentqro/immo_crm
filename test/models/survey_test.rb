# frozen_string_literal: true

require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @year = Date.current.year
    @survey = Survey.new(organization: @organization, year: @year)
  end

  # Q1 — aACTIVE: Active in reporting cycle
  test "aactive returns Oui when organization has transactions in the year" do
    assert @organization.transactions.kept.for_year(@year).exists?,
      "Precondition: organization :one should have transactions in the current year"
    assert_equal "Oui", @survey.aactive
  end

  test "aactive returns Non when organization has no transactions in the year" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_not organizations(:company).transactions.kept.for_year(@year).exists?,
      "Precondition: organization :company should have no transactions in the current year"
    assert_equal "Non", survey.aactive
  end

  # Q2 — aACTIVEPS: Active for purchases/sales in reporting period
  test "aactiveps returns Oui when organization has purchase or sale transactions in the year" do
    assert @organization.transactions.kept.for_year(@year).where(transaction_type: %w[PURCHASE SALE]).exists?,
      "Precondition: organization :one should have purchase/sale transactions in the current year"
    assert_equal "Oui", @survey.aactiveps
  end

  test "aactiveps returns Non when organization has no purchase or sale transactions in the year" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_not organizations(:company).transactions.kept.for_year(@year).where(transaction_type: %w[PURCHASE SALE]).exists?,
      "Precondition: organization :company should have no purchase/sale transactions"
    assert_equal "Non", survey.aactiveps
  end

  # Q3 — aACTIVERENTALS: Active for rentals (monthly rent >= 10,000 EUR) during reporting period
  test "aactiverentals returns Oui when organization has rental transactions with monthly rent >= 10000" do
    # Create a rental transaction with annual value >= 120,000 (i.e., monthly >= 10,000)
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-HIGH",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    assert_equal "Oui", @survey.aactiverentals
  end

  test "aactiverentals returns Non when organization has no qualifying rental transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_not organizations(:company).transactions.kept.for_year(@year)
      .where(transaction_type: "RENTAL")
      .where(Transaction.arel_table[:rental_annual_value].gteq(120_000)).exists?,
      "Precondition: organization :company should have no qualifying rental transactions"
    assert_equal "Non", survey.aactiverentals
  end

  test "aactiverentals returns Non when rentals exist but below 10000 monthly threshold" do
    # The existing rental fixture has transaction_value: 36000 but no rental_annual_value >= 120,000
    assert @organization.transactions.kept.for_year(@year).where(transaction_type: "RENTAL").exists?,
      "Precondition: organization :one should have rental transactions"
    assert_equal "Non", @survey.aactiverentals
  end

  # Q4 — a1101: Total unique clients active during reporting period
  # Includes purchase/sale clients + rental clients with monthly rent >= 10,000 EUR
  test "a1101 returns count of unique clients with qualifying transactions" do
    # Org :one has current-year qualifying transactions for 4 unique clients:
    # natural_person (purchase, sale, cash_payment), legal_entity (high_value, check_payment),
    # pep_client (pep_transaction), vasp_client (crypto_payment)
    # The rental fixture (legal_entity) has no rental_annual_value so it doesn't qualify,
    # but legal_entity qualifies via purchase/sale transactions anyway.
    assert_equal 4, @survey.a1101
  end

  test "a1101 returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1101
  end

  test "a1101 excludes rental clients below 10000 monthly threshold" do
    # Create an organization with only a low-value rental
    org = organizations(:company)
    client = clients(:company_client)
    Transaction.create!(
      organization: org,
      client: client,
      reference: "LOW-RENT",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000 # 5,000/month — below threshold
    )
    survey = Survey.new(organization: org, year: @year)
    assert_equal 0, survey.a1101
  end

  test "a1101 includes rental clients at or above 10000 monthly threshold" do
    org = organizations(:company)
    client = clients(:company_client)
    Transaction.create!(
      organization: org,
      client: client,
      reference: "HIGH-RENT",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000 # 10,000/month — at threshold
    )
    survey = Survey.new(organization: org, year: @year)
    assert_equal 1, survey.a1101
  end

  test "a1101 counts each client only once even with multiple transactions" do
    # natural_person in org :one has purchase, sale, and cash_payment
    # They should only be counted once
    np_txn_count = @organization.transactions.kept.for_year(@year)
      .where(client: clients(:natural_person))
      .where(transaction_type: %w[PURCHASE SALE]).count
    assert np_txn_count > 1, "Precondition: natural_person should have multiple qualifying transactions"
    # Total unique clients should still be 4
    assert_equal 4, @survey.a1101
  end

  test "a1101 excludes soft-deleted transactions" do
    assert @organization.transactions.where(client: clients(:natural_person)).discarded.exists?,
      "Precondition: there should be a discarded transaction for natural_person"
    # Count should not change due to soft-deleted transactions
    assert_equal 4, @survey.a1101
  end

  # Q5 — a1105B: Total number of transactions during reporting period
  # for purchase, sale, and rental (>= 10k/month) of real estate
  test "a1105b counts all qualifying transactions in the year" do
    # Org :one has 7 current-year kept purchase/sale transactions:
    # purchase, sale, cash_payment, high_value, pep_transaction, crypto_payment, check_payment
    # The rental fixture doesn't qualify (no rental_annual_value >= 120,000)
    assert_equal 7, @survey.a1105b
  end

  test "a1105b returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1105b
  end

  test "a1105b includes qualifying rental transactions" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-HIGH-Q5",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    # 7 purchase/sale + 1 qualifying rental = 8
    assert_equal 8, @survey.a1105b
  end

  test "a1105b excludes rental transactions below 10000 monthly threshold" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-LOW-Q5",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000
    )
    # Still 7 — low-value rental excluded
    assert_equal 7, @survey.a1105b
  end

  test "a1105b excludes soft-deleted transactions" do
    assert @organization.transactions.discarded.exists?,
      "Precondition: there should be discarded transactions"
    # discarded_transaction should not be counted
    assert_equal 7, @survey.a1105b
  end

  test "a1105b counts multiple transactions per client separately" do
    # natural_person has purchase, sale, cash_payment = 3 transactions
    np_count = @organization.transactions.kept.for_year(@year)
      .where(client: clients(:natural_person), transaction_type: %w[PURCHASE SALE]).count
    assert np_count > 1, "Precondition: natural_person should have multiple transactions"
    # Each transaction counted individually (not deduplicated by client)
    assert_equal 7, @survey.a1105b
  end
end
