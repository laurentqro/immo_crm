# frozen_string_literal: true

require "test_helper"

class Survey::Fields::ProductsServicesRiskTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "PSR Test Account", personal: false)
    @org = Organization.create!(account: @account, name: "PSR Test Agency", rci_number: "PSR001")
    @survey = Survey.new(organization: @org, year: 2025)
  end

  # === Q150: air233b — Unique buyer clients ===

  test "air233b returns 0 when no transactions exist" do
    assert_equal 0, @survey.send(:air233b)
  end

  test "air233b counts unique buyer clients" do
    buyer = Client.create!(organization: @org, name: "Buyer", client_type: "NATURAL_PERSON")
    seller = Client.create!(organization: @org, name: "Seller", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: buyer, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: seller, transaction_type: "SALE", agency_role: "SELLER_AGENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)

    assert_equal 1, @survey.send(:air233b)
  end

  test "air233b counts a client with multiple purchases only once" do
    buyer = Client.create!(organization: @org, name: "Repeat Buyer", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: buyer, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 2, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: buyer, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 8, 1), transaction_value: 700_000)

    assert_equal 1, @survey.send(:air233b)
  end

  test "air233b counts multiple distinct buyers" do
    buyer1 = Client.create!(organization: @org, name: "Buyer 1", client_type: "NATURAL_PERSON")
    buyer2 = Client.create!(organization: @org, name: "Buyer 2", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL")

    Transaction.create!(organization: @org, client: buyer1, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 4, 1), transaction_value: 400_000)
    Transaction.create!(organization: @org, client: buyer2, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 5, 1), transaction_value: 600_000)

    assert_equal 2, @survey.send(:air233b)
  end

  test "air233b excludes transactions from other years" do
    buyer = Client.create!(organization: @org, name: "Buyer", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: buyer, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2024, 12, 31), transaction_value: 500_000)

    assert_equal 0, @survey.send(:air233b)
  end

  test "air233b excludes soft-deleted transactions" do
    buyer = Client.create!(organization: @org, name: "Buyer", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: buyer, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000, deleted_at: Time.current)

    assert_equal 0, @survey.send(:air233b)
  end

  test "air233b excludes dual agent transactions" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: client, transaction_type: "PURCHASE", agency_role: "DUAL_AGENT", transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)

    assert_equal 0, @survey.send(:air233b)
  end

  # === Q151: air233s — Unique seller clients ===

  test "air233s returns 0 when no transactions exist" do
    assert_equal 0, @survey.send(:air233s)
  end

  test "air233s counts unique seller clients" do
    seller = Client.create!(organization: @org, name: "Seller", client_type: "NATURAL_PERSON")
    buyer = Client.create!(organization: @org, name: "Buyer", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: seller, transaction_type: "SALE", agency_role: "SELLER_AGENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)
    Transaction.create!(organization: @org, client: buyer, transaction_type: "PURCHASE", agency_role: "BUYER_AGENT", transaction_date: Date.new(2025, 3, 1), transaction_value: 500_000)

    assert_equal 1, @survey.send(:air233s)
  end

  test "air233s counts a client with multiple sales only once" do
    seller = Client.create!(organization: @org, name: "Repeat Seller", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: seller, transaction_type: "SALE", agency_role: "SELLER_AGENT", transaction_date: Date.new(2025, 2, 1), transaction_value: 300_000)
    Transaction.create!(organization: @org, client: seller, transaction_type: "SALE", agency_role: "SELLER_AGENT", transaction_date: Date.new(2025, 9, 1), transaction_value: 800_000)

    assert_equal 1, @survey.send(:air233s)
  end

  test "air233s excludes transactions from other years" do
    seller = Client.create!(organization: @org, name: "Seller", client_type: "NATURAL_PERSON")

    Transaction.create!(organization: @org, client: seller, transaction_type: "SALE", agency_role: "SELLER_AGENT", transaction_date: Date.new(2026, 1, 1), transaction_value: 500_000)

    assert_equal 0, @survey.send(:air233s)
  end

  test "air233s excludes soft-deleted transactions" do
    seller = Client.create!(organization: @org, name: "Seller", client_type: "NATURAL_PERSON")
    t = Transaction.create!(organization: @org, client: seller, transaction_type: "SALE", agency_role: "SELLER_AGENT", transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)
    t.discard

    assert_equal 0, @survey.send(:air233s)
  end

  test "air233s excludes dual agent transactions" do
    client = Client.create!(organization: @org, name: "Client", client_type: "NATURAL_PERSON")
    Transaction.create!(organization: @org, client: client, transaction_type: "SALE", agency_role: "DUAL_AGENT", transaction_date: Date.new(2025, 6, 1), transaction_value: 500_000)

    assert_equal 0, @survey.send(:air233s)
  end
end
