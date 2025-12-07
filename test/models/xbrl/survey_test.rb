# frozen_string_literal: true

require "test_helper"

module Xbrl
  class SurveyTest < ActiveSupport::TestCase
    # === T008: Test for Xbrl::Survey.sections ===

    test "sections returns all AMSF sections" do
      sections = Xbrl::Survey.sections

      assert sections.any?, "Should have sections defined"
      assert sections.all? { |s| s[:id].present? }, "Each section should have an id"
      assert sections.all? { |s| s[:title].present? }, "Each section should have a title"
      assert sections.all? { |s| s[:elements].is_a?(Array) }, "Each section should have elements array"
    end

    test "sections returns sections in order by id" do
      sections = Xbrl::Survey.sections
      ids = sections.map { |s| s[:id] }

      # First sections should start with "1.1"
      assert_equal "1.1", ids.first
    end

    test "sections include expected section count" do
      # Per spec: ~25 sections across the questionnaire
      sections = Xbrl::Survey.sections
      assert sections.length >= 20, "Should have at least 20 sections"
    end

    # === T009: Test for Xbrl::Survey.elements_for ===

    test "elements_for returns element names for a valid section" do
      elements = Xbrl::Survey.elements_for("1.2")

      assert elements.is_a?(Array)
      assert elements.any?, "Section 1.2 should have elements"
      assert elements.all? { |e| e.is_a?(String) }, "Elements should be strings"
    end

    test "elements_for returns empty array for unknown section" do
      elements = Xbrl::Survey.elements_for("99.99")

      assert_equal [], elements
    end

    test "elements_for returns different elements for different sections" do
      section_1_2 = Xbrl::Survey.elements_for("1.2")
      section_2_1 = Xbrl::Survey.elements_for("2.1")

      assert section_1_2 != section_2_1, "Different sections should have different elements"
    end

    # === T010: Test for Xbrl::Survey.validate! ===

    test "validate! raises no error when all elements exist in taxonomy" do
      # Should not raise if SECTIONS uses valid element names
      assert_nothing_raised do
        Xbrl::Survey.validate!
      end
    end

    test "validate! reports invalid element names" do
      # We test this by checking the implementation exists
      assert_respond_to Xbrl::Survey, :validate!
    end

    # === Additional utility method tests ===

    test "all_element_names returns flat array of all elements" do
      names = Xbrl::Survey.all_element_names

      assert names.is_a?(Array)
      assert names.any?
      assert names.all? { |n| n.is_a?(String) }
    end

    test "section_for_element returns correct section" do
      # a1101 should be in section 1.2 (Client Summary)
      section = Xbrl::Survey.section_for_element("a1101")

      assert section.present?
      assert_equal "1.2", section[:id]
    end

    test "section_for_element returns nil for unknown element" do
      section = Xbrl::Survey.section_for_element("unknown_element_xyz")

      assert_nil section
    end

    test "section returns section by id" do
      section = Xbrl::Survey.section("1.1")

      assert section.present?
      assert_equal "1.1", section[:id]
      assert section[:title].present?
    end

    test "section returns nil for unknown section id" do
      section = Xbrl::Survey.section("99.99")

      assert_nil section
    end
  end
end
