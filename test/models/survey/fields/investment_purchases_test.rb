# frozen_string_literal: true

require "test_helper"

class Survey::Fields::InvestmentPurchasesTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "Investment Test Account", personal: false)
    @org = Organization.create!(account: @account, name: "Investment Test Agency", rci_number: "INV001")
    @survey = Survey.new(organization: @org, year: 2025)
    @client = Client.create!(organization: @org, name: "Buyer", client_type: "NATURAL_PERSON")
  end

  test "air117 returns 0 when no transactions exist" do
    assert_equal 0, @survey.send(:air117)
  end

  test "air117 counts purchases with investment purpose" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "PURCHASE", purchase_purpose: "INVESTMENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)

    assert_equal 1, @survey.send(:air117)
  end

  test "air117 counts sales with investment purpose" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "SALE", purchase_purpose: "INVESTMENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)

    assert_equal 1, @survey.send(:air117)
  end

  test "air117 excludes residence purpose transactions" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "PURCHASE", purchase_purpose: "RESIDENCE", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: @client, transaction_type: "PURCHASE", purchase_purpose: "INVESTMENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 600_000)

    assert_equal 1, @survey.send(:air117)
  end

  test "air117 excludes rental transactions" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "RENTAL", purchase_purpose: "INVESTMENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 15_000)

    assert_equal 0, @survey.send(:air117)
  end

  test "air117 excludes transactions from other years" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "PURCHASE", purchase_purpose: "INVESTMENT", transaction_date: Date.new(2024, 12, 31), transaction_value: 500_000)

    assert_equal 0, @survey.send(:air117)
  end

  test "air117 excludes transactions with nil purchase purpose" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "PURCHASE", purchase_purpose: nil, transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)

    assert_equal 0, @survey.send(:air117)
  end

  test "air117 excludes soft-deleted transactions" do
    Transaction.create!(organization: @org, client: @client, transaction_type: "PURCHASE", purchase_purpose: "INVESTMENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000, deleted_at: Time.current)

    assert_equal 0, @survey.send(:air117)
  end
end
