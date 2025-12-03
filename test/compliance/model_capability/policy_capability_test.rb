# frozen_string_literal: true

require_relative "model_capability_test_case"

# Tests that our models can answer POLICY questions (Tab 4: Controls).
#
# All 105 aC* elements are Oui/Non questions about organizational policies.
# These are standalone questions with no conditional follow-ups.
#
# Storage: Setting model with xbrl_element column
# Keys: ctrl_<element_code> format (e.g., ctrl_aC1101Z)
#
# Run: bin/rails test test/compliance/model_capability/policy_capability_test.rb
#
class PolicyCapabilityTest < ModelCapabilityTestCase
  # All aC* elements from the AMSF taxonomy (Tab 4: Controls)
  POLICY_ELEMENTS = %w[
    aC1101Z aC1102 aC1102A aC1106
    aC11101 aC11102 aC11103 aC11104 aC11105
    aC11201 aC1125A
    aC11301 aC11302 aC11303 aC11304 aC11305 aC11306 aC11307
    aC114 aC11401 aC11402 aC11403
    aC11501B aC11502 aC11504 aC11508
    aC11601 aC116A
    aC1201 aC1202 aC1203 aC1204 aC1205 aC1206 aC1207 aC1208 aC1209 aC1209B aC1209C
    aC12236 aC12237 aC12333
    aC1301 aC1302 aC1303 aC1304
    aC1401 aC1402 aC1403
    aC1501 aC1503B aC1506 aC1518A
    aC1601 aC1602 aC1608 aC1609 aC1610 aC1611 aC1612 aC1612A aC1614 aC1615
    aC1616A aC1616B aC1616C aC1617 aC1618 aC1619 aC1620 aC1621
    aC1622A aC1622B aC1622F aC1625 aC1626 aC1627 aC1629 aC1630 aC1631
    aC1633 aC1634 aC1635 aC1635A aC1636 aC1637 aC1638A aC1639A aC1640A aC1641A aC1642A
    aC168 aC1701 aC1702 aC1703 aC171
    aC1801 aC1802 aC1806 aC1807 aC1811 aC1812 aC1813 aC1814W
    aC1904
  ].freeze

  # =========================================================================
  # Setting Model Infrastructure
  # =========================================================================

  test "Setting model exists and can store policy answers" do
    assert defined?(Setting), "Setting model should exist"
    assert_model_has_column Setting, :key
    assert_model_has_column Setting, :value
    assert_model_has_column Setting, :value_type
  end

  test "Setting model can store Oui/Non values" do
    setting = Setting.new(
      key: "test_policy",
      value: "true",
      value_type: "boolean",
      category: "controls"
    )
    assert_equal true, setting.typed_value
  end

  test "Setting model has xbrl_element column for taxonomy mapping" do
    assert_model_has_column Setting, :xbrl_element,
      "Setting needs xbrl_element column to map to AMSF taxonomy elements"
  end

  test "Setting has controls category" do
    assert_includes Setting::CATEGORIES, "controls",
      "Setting::CATEGORIES should include 'controls' for Tab 4 policy questions"
  end

  # =========================================================================
  # Policy Element Coverage
  # =========================================================================

  test "Setting.SCHEMA maps all 105 aC* policy elements" do
    mapped = mapped_policy_elements
    unmapped = POLICY_ELEMENTS - mapped

    assert unmapped.empty?,
      "#{unmapped.size} policy elements missing from Setting.SCHEMA: #{unmapped.first(5).join(', ')}..."
  end

  test "all aC* mappings use ctrl_ prefix convention" do
    control_entries = Setting::SCHEMA.select { |key, _| key.start_with?("ctrl_") }

    assert_equal 105, control_entries.size,
      "Should have 105 ctrl_* entries in Setting.SCHEMA"
  end

  test "all aC* mappings have boolean value_type" do
    non_boolean = Setting::SCHEMA.select do |key, config|
      key.start_with?("ctrl_") && config[:value_type] != "boolean"
    end

    assert non_boolean.empty?,
      "All ctrl_* entries should be boolean, found: #{non_boolean.keys.join(', ')}"
  end

  test "all aC* mappings have controls category" do
    wrong_category = Setting::SCHEMA.select do |key, config|
      key.start_with?("ctrl_") && config[:category] != "controls"
    end

    assert wrong_category.empty?,
      "All ctrl_* entries should have 'controls' category, found: #{wrong_category.keys.join(', ')}"
  end

  test "can query settings by xbrl_element" do
    assert_model_has_column Setting, :xbrl_element

    # Verify we can look up by XBRL element code
    assert_can_compute("policy_lookup") do
      Setting.where.not(xbrl_element: nil).count
    end
  end

  # =========================================================================
  # Sample Policy Questions
  # =========================================================================

  test "aC1101Z: Setting.SCHEMA has mapping" do
    assert_policy_element_mapped("aC1101Z")
  end

  test "aC11101: Setting.SCHEMA has mapping" do
    assert_policy_element_mapped("aC11101")
  end

  test "aC11201: Setting.SCHEMA has mapping" do
    assert_policy_element_mapped("aC11201")
  end

  test "aC11301: Setting.SCHEMA has mapping" do
    assert_policy_element_mapped("aC11301")
  end

  test "aC1601: Setting.SCHEMA has mapping" do
    assert_policy_element_mapped("aC1601")
  end

  test "aC1904: Setting.SCHEMA has mapping (last element)" do
    assert_policy_element_mapped("aC1904")
  end

  private

  def mapped_policy_elements
    Setting::SCHEMA.filter_map do |_key, config|
      xbrl = config[:xbrl]
      xbrl if xbrl&.start_with?("aC")
    end
  end

  def assert_policy_element_mapped(element_code)
    mapped = mapped_policy_elements.include?(element_code)
    expected_key = "ctrl_#{element_code}"

    assert mapped, "#{element_code} should be mapped in Setting.SCHEMA as #{expected_key}"
    assert Setting::SCHEMA.key?(expected_key),
      "Setting.SCHEMA should have key '#{expected_key}'"
  end
end
