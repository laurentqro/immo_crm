# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# XbrlCalculationTest verifies that CalculationEngine produces correct
# aggregate values for XBRL elements using known test data.
#
# User Story 3: As an auditor, I want to verify that calculated aggregate
# values (client counts, transaction totals, etc.) are mathematically correct,
# so that I can trust the submitted data.
#
# Run: bin/rails test test/compliance/xbrl_calculation_test.rb
class XbrlCalculationTest < XbrlComplianceTestCase
  def setup
    super
    @submission = submissions(:compliance_test_submission)
    @engine = CalculationEngine.new(@submission)
    # Use the public API to get all calculated values
    @calculated_values = @engine.calculate_all
  end

  # === Dynamic Fixture Counts ===
  # Query actual fixture data to avoid hardcoded values drifting out of sync

  def expected_client_counts
    clients = @organization.clients.kept
    {
      total: clients.count,
      natural_persons: clients.natural_persons.count,
      legal_entities: clients.legal_entities.count,
      trusts: clients.trusts.count,
      peps: clients.peps.count
    }
  end

  def expected_transaction_counts
    txns = @organization.transactions.kept.for_year(@submission.year)
    {
      total: txns.count,
      purchases: txns.purchases.count,
      sales: txns.sales.count,
      total_value: txns.sum(:transaction_value),
      purchase_value: txns.purchases.sum(:transaction_value),
      sale_value: txns.sales.sum(:transaction_value),
      cash_count: txns.where(payment_method: %w[CASH MIXED]).count,
      cash_amount: txns.where(payment_method: %w[CASH MIXED]).sum(:cash_amount)
    }
  end

  # === Client Count Tests (using public API) ===

  test "client count a1101 equals total clients" do
    expected = expected_client_counts[:total]

    assert_equal expected, @calculated_values["a1101"],
      "Total client count (a1101) should be #{expected}"
  end

  test "natural person count a1102 matches actual count" do
    expected = expected_client_counts[:natural_persons]

    assert_equal expected, @calculated_values["a1102"],
      "Natural person count (a1102) should be #{expected}"
  end

  test "legal entity count a11502B matches actual count" do
    expected = expected_client_counts[:legal_entities]

    assert_equal expected, @calculated_values["a11502B"],
      "Legal entity count (a11502B) should be #{expected}"
  end

  test "trust count a11802B matches actual count" do
    expected = expected_client_counts[:trusts]

    assert_equal expected, @calculated_values["a11802B"],
      "Trust count (a11802B) should be #{expected}"
  end

  test "PEP client count a1301 matches actual count" do
    expected = expected_client_counts[:peps]

    assert_equal expected, @calculated_values["a1301"],
      "PEP client count (a1301) should be #{expected}"
  end

  # === Transaction Count Tests (using public API) ===

  test "transaction count a2101B matches actual count" do
    expected = expected_transaction_counts[:total]

    assert_equal expected, @calculated_values["a2101B"],
      "Transaction count (a2101B) should be #{expected}"
  end

  test "purchase transaction count a2102 matches actual count" do
    expected = expected_transaction_counts[:purchases]

    assert_equal expected, @calculated_values["a2102"],
      "Purchase count (a2102) should be #{expected}"
  end

  test "sale transaction count a2103 matches actual count" do
    expected = expected_transaction_counts[:sales]

    assert_equal expected, @calculated_values["a2103"],
      "Sale count (a2103) should be #{expected}"
  end

  # === Transaction Value Tests (using public API) ===

  test "transaction total a2104B equals sum of all transactions" do
    expected = expected_transaction_counts[:total_value]

    assert_equal expected, @calculated_values["a2104B"],
      "Total transaction value (a2104B) should be #{expected}"
  end

  test "purchase total a2105 equals sum of purchases" do
    expected = expected_transaction_counts[:purchase_value]

    assert_equal expected, @calculated_values["a2105"],
      "Purchase total (a2105) should be #{expected}"
  end

  test "sale total a2106 equals sum of sales" do
    expected = expected_transaction_counts[:sale_value]

    assert_equal expected, @calculated_values["a2106"],
      "Sale total (a2106) should be #{expected}"
  end

  # === Payment Method Tests (using public API) ===

  test "cash transaction count a2201 matches actual count" do
    expected = expected_transaction_counts[:cash_count]

    assert_equal expected, @calculated_values["a2201"],
      "Cash transaction count (a2201) should be #{expected}"
  end

  test "cash transaction amount a2202 matches actual amount" do
    expected = expected_transaction_counts[:cash_amount]

    assert_equal expected, @calculated_values["a2202"],
      "Cash transaction amount (a2202) should be #{expected}"
  end

  # === Full Calculation Test ===

  test "calculate_all returns complete statistics hash" do
    # Verify structure includes expected keys
    assert @calculated_values.is_a?(Hash), "calculate_all should return a Hash"
    assert @calculated_values.key?("a1101"), "Should include client count"
    assert @calculated_values.key?("a2101B"), "Should include transaction count"
    assert @calculated_values.key?("a2104B"), "Should include transaction total"
  end

  test "populate_submission_values creates submission_value records" do
    initial_count = @submission.submission_values.count

    @engine.populate_submission_values!

    final_count = @submission.submission_values.count
    assert final_count > initial_count,
      "Should create submission_value records"

    # Verify a sample value was persisted correctly
    expected_total = expected_client_counts[:total].to_s
    client_count_value = @submission.submission_values.find_by(element_name: "a1101")
    assert_equal expected_total, client_count_value&.value,
      "Persisted client count should be '#{expected_total}'"
  end

  # === Nationality Breakdown Tests (using public API) ===

  test "nationality breakdown generates country-specific elements" do
    # Check that calculate_all includes nationality breakdown elements
    fr_elements = @calculated_values.keys.select { |k| k.start_with?("a1103_") }
    assert fr_elements.any?, "Should have nationality breakdown elements"

    # Verify FR count matches actual data
    expected_fr = @organization.clients.kept.where(nationality: "FR").count
    actual_fr = @calculated_values["a1103_FR"]
    assert_equal expected_fr, actual_fr, "French nationality count should match"
  end

  # === Element Name Validation ===

  test "all calculated element names should exist in taxonomy" do
    invalid_elements = @calculated_values.keys.reject do |element_name|
      XbrlTestHelper.valid_element_names.include?(element_name)
    end

    if invalid_elements.any?
      suggestions = invalid_elements.map do |name|
        "#{name} (did you mean: #{XbrlTestHelper.suggest_element_name(name)}?)"
      end

      flunk "CalculationEngine uses invalid element names:\n  #{suggestions.join("\n  ")}"
    end
  end
end
