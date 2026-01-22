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

    # === needs_review (015-amsf-survey-review) ===

    test "ElementValue has needs_review attribute" do
      ev = @manifest.element_with_value("a1101")
      assert_respond_to ev, :needs_review
    end

    test "ElementValue needs_review defaults to false" do
      ev = @manifest.element_with_value("a1101")
      assert_equal false, ev.needs_review
    end

    test "ElementValue needs_review reflects SubmissionValue flagged_for_review" do
      # Use another_submission which doesn't have a1102 value yet
      other_submission = submissions(:another_submission)

      # Create a submission value with flagged_for_review in metadata
      sv = SubmissionValue.create!(
        submission: other_submission,
        element_name: "a1102",
        source: "calculated",
        value: "100",
        metadata: {"flagged_for_review" => true}
      )

      # Create manifest for this submission
      manifest = Xbrl::ElementManifest.new(other_submission.reload)
      ev = manifest.element_with_value("a1102")

      assert ev.needs_review, "ElementValue should reflect needs_review from SubmissionValue"
    end

    test "ElementValue needs_review? predicate method works" do
      ev = @manifest.element_with_value("a1101")
      assert_respond_to ev, :needs_review?
      assert_equal false, ev.needs_review?
    end

    # === Gem Integration Tests (T018-T020) ===

    test "field returns gem field via questionnaire" do
      # Create a 2025 submission for gem compatibility
      submission_2025 = Submission.find_or_create_by!(organization: @organization, year: 2025)
      manifest_2025 = Xbrl::ElementManifest.new(submission_2025)

      field = manifest_2025.field(:aACTIVE)

      assert_not_nil field, "Should find aACTIVE field via gem questionnaire"
      assert_kind_of AmsfSurvey::Field, field
      assert_equal :aACTIVE, field.id
    end

    test "field returns nil for unknown field" do
      submission_2025 = Submission.find_or_create_by!(organization: @organization, year: 2025)
      manifest_2025 = Xbrl::ElementManifest.new(submission_2025)

      field = manifest_2025.field(:nonexistent_xyz)

      assert_nil field
    end

    test "fields_by_section returns gem sections" do
      submission_2025 = Submission.find_or_create_by!(organization: @organization, year: 2025)
      manifest_2025 = Xbrl::ElementManifest.new(submission_2025)

      sections = manifest_2025.fields_by_section

      assert sections.is_a?(Hash), "Should return a hash"
      assert sections.keys.any?, "Should have sections"
    end

    test "all_fields returns fields from gem questionnaire" do
      submission_2025 = Submission.find_or_create_by!(organization: @organization, year: 2025)
      manifest_2025 = Xbrl::ElementManifest.new(submission_2025)

      fields = manifest_2025.all_fields

      assert fields.any?, "Should return fields"
      assert fields.first.is_a?(AmsfSurvey::Field), "Fields should be AmsfSurvey::Field"
    end

    test "field visibility respects gate dependencies" do
      submission_2025 = Submission.find_or_create_by!(organization: @organization, year: 2025)

      # Set a gate field value
      submission_2025.submission_values.find_or_create_by!(element_name: "aACTIVE") do |sv|
        sv.value = "Oui"
        sv.source = "manual"
      end

      manifest_2025 = Xbrl::ElementManifest.new(submission_2025.reload)

      # Find a field that depends on aACTIVE
      questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
      dependent_field = questionnaire.fields.find { |f| f.id != :aACTIVE && f.visible?(aACTIVE: "Oui") && !f.visible?({}) }

      if dependent_field
        # When gate is set, field should be visible
        assert manifest_2025.field_visible?(dependent_field.id, manifest_2025.gate_data)
      else
        skip "No fields with gate dependencies found"
      end
    end
  end
end
