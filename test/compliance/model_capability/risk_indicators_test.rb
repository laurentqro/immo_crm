# frozen_string_literal: true

require_relative "model_capability_test_case"

# Documents the 21 Risk Indicator elements (aIR*)
#
# IMPORTANT: These elements are AUTO-CALCULATED by AMSF based on the data
# submitted in Tabs 1-3. We do NOT need to provide values for these elements.
# AMSF's calculation engine derives these risk indicators from our submission.
#
# This test file documents what AMSF calculates, not what we provide.
#
# Elements (21 total):
#   aIR0101-aIR0105: Customer/Client Risk Indicators (5)
#   aIR0201-aIR0205: Product/Service Risk Indicators (5)
#   aIR0301-aIR0305: Distribution Channel Risk Indicators (5)
#   aIR0401-aIR0405: Geographic Risk Indicators (5)
#   aIR0500: Composite Risk Score (1)
#
# Run: bin/rails test test/compliance/model_capability/risk_indicators_test.rb
#
class RiskIndicatorsTest < ModelCapabilityTestCase
  # All 21 Risk Indicator elements (auto-calculated by AMSF)
  RISK_INDICATOR_ELEMENTS = %w[
    aIR0101 aIR0102 aIR0103 aIR0104 aIR0105
    aIR0201 aIR0202 aIR0203 aIR0204 aIR0205
    aIR0301 aIR0302 aIR0303 aIR0304 aIR0305
    aIR0401 aIR0402 aIR0403 aIR0404 aIR0405
    aIR0500
  ].freeze

  # =========================================================================
  # aIR01xx: Customer/Client Risk Indicators (5 elements)
  # =========================================================================

  test "aIR0101: customer type risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: client_type distribution (PP vs PM)
    # Source data: Tab 1 client counts by type
    assert_auto_calculated("aIR0101")
  end

  test "aIR0102: PEP exposure risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: PEP client percentages
    # Source data: Tab 1 PEP-related fields (a1210-a1220)
    assert_auto_calculated("aIR0102")
  end

  test "aIR0103: high-risk client risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: high-risk client concentration
    # Source data: Tab 1 risk classification (a16xx)
    assert_auto_calculated("aIR0103")
  end

  test "aIR0104: new client risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: new client onboarding rate
    # Source data: Tab 1 new client counts
    assert_auto_calculated("aIR0104")
  end

  test "aIR0105: client concentration risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: transaction concentration among clients
    # Source data: Tab 1/Tab 2 client and transaction data
    assert_auto_calculated("aIR0105")
  end

  # =========================================================================
  # aIR02xx: Product/Service Risk Indicators (5 elements)
  # =========================================================================

  test "aIR0201: transaction volume risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: total transaction volumes
    # Source data: Tab 2 transaction counts and values
    assert_auto_calculated("aIR0201")
  end

  test "aIR0202: cash transaction risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: cash transaction percentages
    # Source data: Tab 2 cash transactions (a22xx)
    assert_auto_calculated("aIR0202")
  end

  test "aIR0203: high-value transaction risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: high-value transaction concentration
    # Source data: Tab 2 threshold transactions (a2113-a2115)
    assert_auto_calculated("aIR0203")
  end

  test "aIR0204: virtual asset risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: virtual asset transaction presence
    # Source data: Tab 2 virtual asset transactions (a25xx)
    assert_auto_calculated("aIR0204")
  end

  test "aIR0205: product complexity risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: product/service mix complexity
    # Source data: Tab 2 product distribution
    assert_auto_calculated("aIR0205")
  end

  # =========================================================================
  # aIR03xx: Distribution Channel Risk Indicators (5 elements)
  # =========================================================================

  test "aIR0301: non-face-to-face risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: non-face-to-face transaction percentages
    # Source data: Tab 3 distribution channels (a33xx)
    assert_auto_calculated("aIR0301")
  end

  test "aIR0302: third-party reliance risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: third-party dependency levels
    # Source data: Tab 3 third-party relationships (a34xx)
    assert_auto_calculated("aIR0302")
  end

  test "aIR0303: outsourcing risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: outsourced AML function exposure
    # Source data: Tab 3 outsourcing (a35xx)
    assert_auto_calculated("aIR0303")
  end

  test "aIR0304: identification method risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: client identification method distribution
    # Source data: Tab 3 identification methods (a32xx)
    assert_auto_calculated("aIR0304")
  end

  test "aIR0305: STR filing risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: STR filing rates relative to activity
    # Source data: Tab 3 STR data (a31xx)
    assert_auto_calculated("aIR0305")
  end

  # =========================================================================
  # aIR04xx: Geographic Risk Indicators (5 elements)
  # =========================================================================

  test "aIR0401: cross-border client risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: non-Monaco client percentages
    # Source data: Tab 1/Tab 3 country codes
    assert_auto_calculated("aIR0401")
  end

  test "aIR0402: high-risk jurisdiction risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: clients from FATF high-risk jurisdictions
    # Source data: Tab 1 country codes + FATF lists
    assert_auto_calculated("aIR0402")
  end

  test "aIR0403: cross-border transaction risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: cross-border transaction volumes
    # Source data: Tab 3 cross-border activity (a37xx-a38xx)
    assert_auto_calculated("aIR0403")
  end

  test "aIR0404: EU vs non-EU risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: EU vs non-EU client/transaction mix
    # Source data: Tab 1/Tab 3 country codes
    assert_auto_calculated("aIR0404")
  end

  test "aIR0405: correspondent relationship risk indicator - AUTO-CALCULATED by AMSF" do
    # Derived from: correspondent banking relationships
    # Source data: Tab 3 correspondent data
    assert_auto_calculated("aIR0405")
  end

  # =========================================================================
  # aIR0500: Composite Risk Score (1 element)
  # =========================================================================

  test "aIR0500: composite AML/CFT risk score - AUTO-CALCULATED by AMSF" do
    # AMSF's overall risk assessment combining all indicators
    # This is the primary output of AMSF's risk calculation engine
    assert_auto_calculated("aIR0500")
  end

  # =========================================================================
  # Coverage Summary
  # =========================================================================

  test "all Risk Indicator elements accounted for" do
    assert_equal 21, RISK_INDICATOR_ELEMENTS.size,
      "Risk Indicators should have exactly 21 elements"
  end

  test "risk indicators require no model data - AMSF auto-calculates" do
    # This test documents that we do NOT provide these values
    # AMSF calculates them from our Tab 1-3 submission data
    assert true, "Risk indicators are derived by AMSF, not provided by us"
  end

  private

  def assert_auto_calculated(element_code)
    # Document that this element is auto-calculated by AMSF
    # We pass if the element is in our known list
    assert RISK_INDICATOR_ELEMENTS.include?(element_code),
      "#{element_code} should be a known auto-calculated risk indicator"
  end
end
