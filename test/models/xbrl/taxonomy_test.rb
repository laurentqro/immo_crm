# frozen_string_literal: true

require "test_helper"

module Xbrl
  class TaxonomyTest < ActiveSupport::TestCase
    setup do
      Xbrl::Taxonomy.reload!
    end

    test "loads elements from taxonomy files" do
      elements = Xbrl::Taxonomy.elements
      assert elements.any?, "Should load elements from taxonomy"
      assert elements.count > 100, "Should have many elements (taxonomy has ~150+)"
    end

    test "element returns TaxonomyElement for valid name" do
      element = Xbrl::Taxonomy.element("a1101")
      assert_not_nil element
      assert_instance_of Xbrl::TaxonomyElement, element
      assert_equal "a1101", element.name
    end

    test "element returns nil for unknown name" do
      element = Xbrl::Taxonomy.element("nonexistent")
      assert_nil element
    end

    test "correctly identifies integer type from XSD" do
      element = Xbrl::Taxonomy.element("a1101")
      assert_not_nil element
      assert_equal :integer, element.type
      assert element.integer?
      assert element.numeric?
    end

    test "correctly identifies monetary type from XSD" do
      element = Xbrl::Taxonomy.element("a1106B")
      assert_not_nil element
      assert_equal :monetary, element.type
      assert element.monetary?
      assert element.numeric?
      assert_equal "unit_EUR", element.unit_ref
      assert_equal "2", element.decimals
    end

    test "correctly identifies boolean type from XSD enumeration" do
      # Elements with Oui/Non enumeration
      element = Xbrl::Taxonomy.element("a11001BTOLA")
      assert_not_nil element
      assert_equal :boolean, element.type
      assert element.boolean?
    end

    test "extracts French labels from label linkbase" do
      element = Xbrl::Taxonomy.element("a1101")
      assert_not_nil element.label
      assert element.label.include?("clients"), "Label should contain 'clients'"
    end

    test "label_text strips HTML tags" do
      element = Xbrl::Taxonomy.element("a1101")
      assert_not_nil element.label_text
      refute element.label_text.include?("<"), "Should not contain HTML tags"
      refute element.label_text.include?(">"), "Should not contain HTML tags"
    end

    test "assigns sections from presentation linkbase" do
      element = Xbrl::Taxonomy.element("a1101")
      assert_not_nil element.section
    end

    test "elements are sorted by presentation order" do
      elements = Xbrl::Taxonomy.elements
      orders = elements.map(&:order)
      assert_equal orders, orders.sort, "Elements should be sorted by order"
    end

    test "elements_by_section groups correctly" do
      sections = Xbrl::Taxonomy.elements_by_section
      assert sections.is_a?(Hash)
      assert sections.any?
      sections.each do |section_name, elements|
        assert elements.all? { |e| e.section == section_name }
      end
    end

    test "identifies dimensional element a1103" do
      element = Xbrl::Taxonomy.element("a1103")
      assert_not_nil element
      assert element.dimensional?, "a1103 should be marked as dimensional"
    end
  end
end
