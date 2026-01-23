# frozen_string_literal: true

require_relative "model_capability_test_case"

# Tests that our models can answer POLICY questions (Tab 4: Controls).
#
# All 105 aC* elements are Oui/Non questions about organizational policies.
# These are standalone questions with no conditional follow-ups.
#
# Storage: Setting model with key column
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
  end

  test "Setting has controls category" do
    assert_includes Setting::CATEGORIES, "controls",
      "Setting::CATEGORIES should include 'controls' for Tab 4 policy questions"
  end
end
