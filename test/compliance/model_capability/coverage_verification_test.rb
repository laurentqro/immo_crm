# frozen_string_literal: true

require_relative "model_capability_test_case"

# Verifies complete 323-element coverage across all AMSF taxonomy sections.
#
# This test aggregates element counts from all section-specific test files
# and confirms we have capability tests for all 323 AMSF taxonomy elements.
#
# Section Breakdown:
#   Tab 1 - Customer Risk:      104 elements (a1xxx)
#   Tab 2 - Products/Services:   37 elements (a2xxx)
#   Tab 3 - STR/Distribution:    44 elements (a3xxx)
#   Controls (Policy):          105 elements (aCxxxx)
#   Risk Indicators:             21 elements (aIRxxxx) - AMSF auto-calculated
#   Entity Info/Other:           10 elements (aACTIVE, aB, aG, etc.)
#   Signatories:                  2 elements (aS1, aS2)
#                               ---
#   TOTAL:                      323 elements
#
# Run: bin/rails test test/compliance/model_capability/coverage_verification_test.rb
#
class CoverageVerificationTest < ModelCapabilityTestCase
  # Element counts by section (must match section test files)
  SECTION_COUNTS = {
    tab1_customer_risk: 104,
    tab2_products_services: 37,
    tab3_str_distribution: 44,
    controls_policy: 105,
    risk_indicators: 21,
    entity_info: 10,
    signatories: 2
  }.freeze

  TOTAL_ELEMENTS = 323

  test "total element count matches AMSF taxonomy (323 elements)" do
    actual_total = SECTION_COUNTS.values.sum
    assert_equal TOTAL_ELEMENTS, actual_total,
      "Section counts should sum to #{TOTAL_ELEMENTS}, got #{actual_total}"
  end

  test "Tab 1 Customer Risk coverage (104 elements)" do
    require_relative "tab1_customer_risk_test"
    assert_equal SECTION_COUNTS[:tab1_customer_risk],
      Tab1CustomerRiskTest::TAB1_ELEMENTS.size,
      "Tab 1 should have #{SECTION_COUNTS[:tab1_customer_risk]} elements"
  end

  test "Tab 2 Products/Services coverage (37 elements)" do
    require_relative "tab2_products_services_test"
    assert_equal SECTION_COUNTS[:tab2_products_services],
      Tab2ProductsServicesTest::TAB2_ELEMENTS.size,
      "Tab 2 should have #{SECTION_COUNTS[:tab2_products_services]} elements"
  end

  test "Tab 3 STR/Distribution coverage (44 elements)" do
    require_relative "tab3_str_distribution_test"
    assert_equal SECTION_COUNTS[:tab3_str_distribution],
      Tab3StrDistributionTest::TAB3_ELEMENTS.size,
      "Tab 3 should have #{SECTION_COUNTS[:tab3_str_distribution]} elements"
  end

  test "Controls/Policy coverage (105 elements)" do
    require_relative "policy_capability_test"
    assert_equal SECTION_COUNTS[:controls_policy],
      PolicyCapabilityTest::POLICY_ELEMENTS.size,
      "Controls should have #{SECTION_COUNTS[:controls_policy]} elements"
  end

  test "Risk Indicators coverage (21 elements - auto-calculated)" do
    require_relative "risk_indicators_test"
    assert_equal SECTION_COUNTS[:risk_indicators],
      RiskIndicatorsTest::RISK_INDICATOR_ELEMENTS.size,
      "Risk Indicators should have #{SECTION_COUNTS[:risk_indicators]} elements"
  end

  test "Entity Info coverage (10 elements)" do
    require_relative "entity_info_test"
    assert_equal SECTION_COUNTS[:entity_info],
      EntityInfoTest::OTHER_ELEMENTS.size,
      "Entity Info should have #{SECTION_COUNTS[:entity_info]} elements"
  end

  test "Signatory coverage (2 elements)" do
    require_relative "signatory_capability_test"
    assert_equal SECTION_COUNTS[:signatories],
      SignatoryCapabilityTest::SIGNATORY_ELEMENTS.size,
      "Signatories should have #{SECTION_COUNTS[:signatories]} elements"
  end

  test "all sections documented with test files" do
    test_files = [
      "tab1_customer_risk_test.rb",
      "tab2_products_services_test.rb",
      "tab3_str_distribution_test.rb",
      "policy_capability_test.rb",
      "risk_indicators_test.rb",
      "entity_info_test.rb",
      "signatory_capability_test.rb"
    ]

    test_dir = File.dirname(__FILE__)
    test_files.each do |file|
      assert File.exist?(File.join(test_dir, file)),
        "Missing test file: #{file}"
    end
  end

  test "no duplicate elements across sections" do
    require_relative "tab1_customer_risk_test"
    require_relative "tab2_products_services_test"
    require_relative "tab3_str_distribution_test"
    require_relative "policy_capability_test"
    require_relative "risk_indicators_test"
    require_relative "entity_info_test"
    require_relative "signatory_capability_test"

    all_elements = [
      Tab1CustomerRiskTest::TAB1_ELEMENTS,
      Tab2ProductsServicesTest::TAB2_ELEMENTS,
      Tab3StrDistributionTest::TAB3_ELEMENTS,
      PolicyCapabilityTest::POLICY_ELEMENTS,
      RiskIndicatorsTest::RISK_INDICATOR_ELEMENTS,
      EntityInfoTest::OTHER_ELEMENTS,
      SignatoryCapabilityTest::SIGNATORY_ELEMENTS
    ].flatten

    duplicates = all_elements.select { |e| all_elements.count(e) > 1 }.uniq
    assert duplicates.empty?,
      "Found duplicate elements across sections: #{duplicates.join(', ')}"
  end
end
