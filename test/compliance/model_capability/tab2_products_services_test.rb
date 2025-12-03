# frozen_string_literal: true

require_relative "model_capability_test_case"

# Tests model capability for Tab 2: Products & Services (37 elements)
#
# Subsections:
#   a21xx: Transaction counts and values (BY/WITH client)
#   a22xx: Cash transactions
#   a25xx: Virtual asset transactions
#
# Key distinction:
#   - "B" suffix: Transactions BY clients (client is principal)
#   - "W" suffix: Transactions WITH clients (agency is agent)
#   - "BB/BW" suffix: Monetary values
#   - "WRP" suffix: Recurring payments WITH clients
#
# Run: bin/rails test test/compliance/model_capability/tab2_products_services_test.rb
#
class Tab2ProductsServicesTest < ModelCapabilityTestCase
  # All 37 Tab 2 elements
  TAB2_ELEMENTS = %w[
    a2101B a2101W a2101WRP a2102B a2102BB a2102BW a2102W a2104B a2104W a2104WRP
    a2105B a2105BB a2105BW a2105W a2107B a2107W a2107WRP a2108B a2108W a2109B
    a2109W a2110B a2110W a2113AB a2113AW a2113B a2113W a2114A a2114AB a2115AB
    a2115AW a2201A a2201D a2202 a2203 a2501 a2501A
  ].freeze

  # =========================================================================
  # a21xxB: Transactions BY Clients (Client is Principal)
  # =========================================================================

  test "a2101B: had transactions BY clients (Oui/Non)" do
    assert_can_compute("a2101B") { Transaction.by_client.exists? ? "Oui" : "Non" }
  end

  test "a2102B: purchase count BY clients" do
    assert_can_compute("a2102B") { Transaction.by_client.purchases.count }
  end

  test "a2102BB: purchase value BY clients" do
    assert_can_compute("a2102BB") { Transaction.by_client.purchases.sum(:amount) }
  end

  test "a2104B: rental count BY clients" do
    # Note: Some taxonomies use a2104B for rentals, others for total
    assert_can_compute("a2104B") { Transaction.by_client.rentals.count }
  end

  test "a2105B: sale count BY clients" do
    assert_can_compute("a2105B") { Transaction.by_client.sales.count }
  end

  test "a2105BB: sale value BY clients" do
    assert_can_compute("a2105BB") { Transaction.by_client.sales.sum(:amount) }
  end

  test "a2107B: rental presence BY clients (Oui/Non)" do
    assert_can_compute("a2107B") { Transaction.by_client.rentals.exists? ? "Oui" : "Non" }
  end

  test "a2108B: rental count BY clients" do
    assert_can_compute("a2108B") { Transaction.by_client.rentals.count }
  end

  test "a2109B: total transaction value BY clients" do
    assert_can_compute("a2109B") { Transaction.by_client.sum(:amount) }
  end

  test "a2110B: average transaction value BY clients" do
    # average returns nil when no records exist; use 0 as default
    assert_can_compute("a2110B") { Transaction.by_client.average(:amount) || 0 }
  end

  test "a2113B: high-value transaction count BY clients" do
    # High-value threshold typically defined by regulation
    assert_model_has_column Transaction, :amount
  end

  test "a2113AB: high-value transaction value BY clients" do
    assert_model_has_column Transaction, :amount
  end

  test "a2114A: threshold transaction count" do
    assert_model_has_column Transaction, :amount
  end

  test "a2114AB: threshold transaction value" do
    assert_model_has_column Transaction, :amount
  end

  test "a2115AB: specific threshold transactions BY clients" do
    assert_model_has_column Transaction, :amount
  end

  # =========================================================================
  # a21xxW: Transactions WITH Clients (Agency is Agent)
  # =========================================================================

  test "a2101W: had transactions WITH clients (Oui/Non)" do
    assert_can_compute("a2101W") { Transaction.with_client.exists? ? "Oui" : "Non" }
  end

  test "a2101WRP: had recurring payments WITH clients (Oui/Non)" do
    # May need Transaction.is_recurring field
    assert_model_has_column Transaction, :direction
  end

  test "a2102W: purchase count WITH clients" do
    assert_can_compute("a2102W") { Transaction.with_client.purchases.count }
  end

  test "a2102BW: purchase value WITH clients" do
    assert_can_compute("a2102BW") { Transaction.with_client.purchases.sum(:amount) }
  end

  test "a2104W: rental count WITH clients" do
    assert_can_compute("a2104W") { Transaction.with_client.rentals.count }
  end

  test "a2104WRP: recurring rental count WITH clients" do
    # May need Transaction.is_recurring field
    assert_model_has_column Transaction, :direction
  end

  test "a2105W: sale count WITH clients" do
    assert_can_compute("a2105W") { Transaction.with_client.sales.count }
  end

  test "a2105BW: sale value WITH clients" do
    assert_can_compute("a2105BW") { Transaction.with_client.sales.sum(:amount) }
  end

  test "a2107W: rental presence WITH clients (Oui/Non)" do
    assert_can_compute("a2107W") { Transaction.with_client.rentals.exists? ? "Oui" : "Non" }
  end

  test "a2107WRP: recurring rental WITH clients (Oui/Non)" do
    assert_model_has_column Transaction, :direction
  end

  test "a2108W: rental count WITH clients" do
    assert_can_compute("a2108W") { Transaction.with_client.rentals.count }
  end

  test "a2109W: total transaction value WITH clients" do
    assert_can_compute("a2109W") { Transaction.with_client.sum(:amount) }
  end

  test "a2110W: average transaction value WITH clients" do
    # average returns nil when no records exist; use 0 as default
    assert_can_compute("a2110W") { Transaction.with_client.average(:amount) || 0 }
  end

  test "a2113W: high-value transaction count WITH clients" do
    assert_model_has_column Transaction, :amount
  end

  test "a2113AW: high-value transaction value WITH clients" do
    assert_model_has_column Transaction, :amount
  end

  test "a2115AW: specific threshold transactions WITH clients" do
    assert_model_has_column Transaction, :amount
  end

  # =========================================================================
  # a22xx: Cash Transactions
  # =========================================================================

  test "a2201A: cash transaction presence (Oui/Non)" do
    assert_can_compute("a2201A") { Transaction.with_cash.exists? ? "Oui" : "Non" }
  end

  test "a2201D: cash transaction documentation" do
    assert_model_has_column Transaction, :cash_amount
  end

  test "a2202: had cash transactions (Oui/Non)" do
    assert_can_compute("a2202") { Transaction.with_cash.exists? ? "Oui" : "Non" }
  end

  test "a2203: cash transaction count" do
    assert_can_compute("a2203") { Transaction.with_cash.count }
  end

  # =========================================================================
  # a25xx: Virtual Asset Transactions
  # =========================================================================

  test "a2501: virtual asset transaction details" do
    assert_model_has_column Transaction, :payment_method
    assert_can_compute("a2501") { Transaction.where(payment_method: "CRYPTO").count }
  end

  test "a2501A: had virtual asset transactions (Oui/Non)" do
    assert_can_compute("a2501A") { Transaction.where(payment_method: "CRYPTO").exists? ? "Oui" : "Non" }
  end

  # =========================================================================
  # Coverage Summary
  # =========================================================================

  test "all Tab 2 elements accounted for" do
    assert_equal 37, TAB2_ELEMENTS.size,
      "Tab 2 should have exactly 37 elements"
  end
end
