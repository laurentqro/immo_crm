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
end
