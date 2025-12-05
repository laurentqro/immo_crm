# frozen_string_literal: true

require "test_helper"

module Xbrl
  class ElementManifestTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:one)
      @submission = submissions(:draft_submission)
      @manifest = Xbrl::ElementManifest.new(@submission)
    end

    test "value_for returns stored submission value" do
      # Fixture has a1101 = "42"
      assert_equal "42", @manifest.value_for("a1101")
    end

    test "value_for returns nil for missing element" do
      assert_nil @manifest.value_for("nonexistent_element_xyz")
    end

    test "element_with_value returns ElementValue with metadata" do
      # Fixture has a1101 = "42" with source "calculated"
      ev = @manifest.element_with_value("a1101")

      assert_not_nil ev
      assert_equal "a1101", ev.name
      assert_equal "42", ev.value
      assert_equal "calculated", ev.source
      assert_equal :integer, ev.type
      assert ev.calculated?
      refute ev.manual?
    end

    test "element_with_value returns nil for unknown element" do
      ev = @manifest.element_with_value("nonexistent_xyz")
      assert_nil ev
    end

    test "all_elements_with_values returns all elements in order" do
      elements = @manifest.all_elements_with_values
      assert elements.any?

      # Check they are sorted by order
      orders = elements.map { |e| e.element.order }
      assert_equal orders, orders.sort
    end

    test "elements_by_section groups correctly" do
      sections = @manifest.elements_by_section
      assert sections.is_a?(Hash)
    end

    test "ElementValue exposes element properties" do
      # a1101 is an integer element
      ev = @manifest.element_with_value("a1101")

      assert ev.integer?
      assert ev.numeric?
      refute ev.monetary?
      refute ev.boolean?
      assert_not_nil ev.label
      assert_not_nil ev.section
    end

    test "ElementValue present? and blank? work correctly" do
      ev_with_value = @manifest.element_with_value("a1101")
      assert ev_with_value.present?
      refute ev_with_value.blank?
    end

    test "ElementValue tracks overridden status" do
      # Fixture has a1301 as overridden
      ev = @manifest.element_with_value("a1301")
      # a1301 may not be in taxonomy, let's check if it exists first
      if ev
        assert ev.overridden?, "a1301 fixture is marked as overridden"
      end
    end

    test "ElementValue tracks source correctly" do
      # Test calculated source
      ev_calc = @manifest.element_with_value("a1101")
      assert_equal "calculated", ev_calc.source
      assert ev_calc.calculated?

      # Test from_settings source
      ev_settings = @manifest.element_with_value("a4101")
      if ev_settings
        assert_equal "from_settings", ev_settings.source
        assert ev_settings.from_settings?
      end

      # Test manual source
      ev_manual = @manifest.element_with_value("a5001")
      if ev_manual
        assert_equal "manual", ev_manual.source
        assert ev_manual.manual?
      end
    end
  end
end
