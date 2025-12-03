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
  end

  # === Client Count Tests ===

  test "client count a1101 equals total clients" do
    # compliance_test_org has:
    # - 10 natural persons (calc_natural_1..10)
    # - 5 legal entities (calc_legal_1..5)
    # - 2 PEP clients (calc_pep_1..2)
    # - 1 trust (calc_trust_1)
    # Total: 18 clients

    stats = @engine.send(:client_statistics)

    # Note: PEP clients are also counted as natural persons in a1101
    # So total = 10 non-PEP natural + 2 PEP natural + 5 legal + 1 trust = 18
    assert_equal 18, stats["a1101"],
      "Total client count (a1101) should be 18"
  end

  test "natural person count a1102 matches fixture count" do
    # 10 natural persons (non-PEP) + 2 PEP natural persons = 12
    stats = @engine.send(:client_statistics)

    assert_equal 12, stats["a1102"],
      "Natural person count (a1102) should be 12"
  end

  test "legal entity count a11502B matches fixture count" do
    # 5 legal entities (calc_legal_1..5)
    stats = @engine.send(:client_statistics)

    assert_equal 5, stats["a11502B"],
      "Legal entity count (a11502B) should be 5"
  end

  test "trust count a11802B matches fixture count" do
    # 1 trust (calc_trust_1)
    stats = @engine.send(:client_statistics)

    assert_equal 1, stats["a11802B"],
      "Trust count (a11802B) should be 1"
  end

  test "PEP client count a1301 matches fixture count" do
    # 2 PEP clients (calc_pep_1, calc_pep_2)
    stats = @engine.send(:client_statistics)

    assert_equal 2, stats["a1301"],
      "PEP client count (a1301) should be 2"
  end

  # === Transaction Count Tests ===

  test "transaction count a2101B matches fixture count" do
    # 4 transactions total: calc_txn_1, calc_txn_2, calc_txn_3, calc_txn_cash
    stats = @engine.send(:transaction_statistics)

    assert_equal 4, stats["a2101B"],
      "Transaction count (a2101B) should be 4"
  end

  test "purchase transaction count a2102 matches" do
    # 3 purchases: calc_txn_1, calc_txn_2, calc_txn_cash
    stats = @engine.send(:transaction_statistics)

    assert_equal 3, stats["a2102"],
      "Purchase count (a2102) should be 3"
  end

  test "sale transaction count a2103 matches" do
    # 1 sale: calc_txn_3
    stats = @engine.send(:transaction_statistics)

    assert_equal 1, stats["a2103"],
      "Sale count (a2103) should be 1"
  end

  # === Transaction Value Tests ===

  test "transaction total a2104B equals sum of all transactions" do
    # 100,000 + 200,000 + 300,000 + 50,000 = 650,000
    stats = @engine.send(:transaction_values)

    assert_equal 650_000.0, stats["a2104B"],
      "Total transaction value (a2104B) should be 650,000"
  end

  test "purchase total a2105 equals sum of purchases" do
    # 100,000 + 200,000 + 50,000 = 350,000
    stats = @engine.send(:transaction_values)

    assert_equal 350_000.0, stats["a2105"],
      "Purchase total (a2105) should be 350,000"
  end

  test "sale total a2106 equals sum of sales" do
    # 300,000
    stats = @engine.send(:transaction_values)

    assert_equal 300_000.0, stats["a2106"],
      "Sale total (a2106) should be 300,000"
  end

  # === Payment Method Tests ===

  test "cash transaction count a2201 matches" do
    # 1 cash transaction: calc_txn_cash
    stats = @engine.send(:payment_method_statistics)

    assert_equal 1, stats["a2201"],
      "Cash transaction count (a2201) should be 1"
  end

  test "cash transaction amount a2202 matches" do
    # calc_txn_cash has cash_amount: 50,000
    stats = @engine.send(:payment_method_statistics)

    assert_equal 50_000.0, stats["a2202"],
      "Cash transaction amount (a2202) should be 50,000"
  end

  # === Full Calculation Test ===

  test "calculate_all returns complete statistics hash" do
    result = @engine.calculate_all

    # Verify structure includes expected keys
    assert result.is_a?(Hash), "calculate_all should return a Hash"
    assert result.key?("a1101"), "Should include client count"
    assert result.key?("a2101B"), "Should include transaction count"
    assert result.key?("a2104B"), "Should include transaction total"
  end

  test "populate_submission_values creates submission_value records" do
    initial_count = @submission.submission_values.count

    @engine.populate_submission_values!

    final_count = @submission.submission_values.count
    assert final_count > initial_count,
      "Should create submission_value records"

    # Verify a sample value was persisted correctly
    client_count_value = @submission.submission_values.find_by(element_name: "a1101")
    assert_equal "18", client_count_value&.value,
      "Persisted client count should be '18'"
  end

  # === Nationality Breakdown Tests ===

  test "nationality breakdown generates country-specific elements" do
    result = @engine.send(:client_nationality_breakdown)

    # compliance test fixtures have various nationalities:
    # FR (calc_natural_1, calc_natural_5, calc_pep_1, calc_legal_5), DE, IT, MC, GB, ES, CH, BE, NL
    assert result.any?, "Should have nationality breakdown"

    # Check FR count (should be 4: calc_natural_1, calc_natural_5, calc_pep_1, calc_legal_5)
    fr_count = result["a1103_FR"]
    assert_equal 4, fr_count, "French nationality count should be 4"
  end

  # === Element Name Validation ===

  test "all calculated element names should exist in taxonomy" do
    # This test validates that CalculationEngine uses correct element names
    result = @engine.calculate_all

    invalid_elements = result.keys.reject do |element_name|
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
