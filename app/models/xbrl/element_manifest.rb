# frozen_string_literal: true

module Xbrl
  # ElementManifest defines computation logic for XBRL elements.
  # Works with Taxonomy (metadata) and CalculationEngine (existing computations).
  #
  # This is a thin layer that:
  # 1. Identifies which elements are computable vs manual
  # 2. Provides a consistent interface for value retrieval
  # 3. Combines taxonomy metadata with stored submission values
  #
  # Usage:
  #   manifest = Xbrl::ElementManifest.new(submission)
  #   manifest.value_for("a1101")        # => "42"
  #   manifest.element_with_value("a1101") # => { element: TaxonomyElement, value: "42", source: "calculated" }
  #   manifest.all_elements_with_values  # => Array of all elements with their values
  #
  class ElementManifest
    attr_reader :submission

    def initialize(submission)
      @submission = submission
      @stored_values = submission.submission_values.index_by(&:element_name)
    end

    # Get raw value for an element
    def value_for(element_name)
      @stored_values[element_name]&.value
    end

    # Get submission value record for an element
    def submission_value_for(element_name)
      @stored_values[element_name]
    end

    # Get element metadata with its value
    def element_with_value(element_name)
      element = Taxonomy.element(element_name)
      return nil unless element

      sv = @stored_values[element_name]

      ElementValue.new(
        element: element,
        value: sv&.value,
        source: sv&.source,
        overridden: sv&.overridden?,
        confirmed: sv&.confirmed?
      )
    end

    # Get all elements with their values, in presentation order.
    # Only returns elements that have actual values stored.
    def all_elements_with_values
      @stored_values.keys.filter_map do |element_name|
        element_with_value(element_name)
      end.sort_by { |ev| ev.element.order }
    end

    # Get elements grouped by section with their values
    def elements_by_section
      all_elements_with_values.group_by { |ev| ev.element.section }
    end

    # Value object combining element metadata with submission value
    class ElementValue
      attr_reader :element, :value, :source, :overridden, :confirmed

      def initialize(element:, value:, source:, overridden:, confirmed:)
        @element = element
        @value = value
        @source = source
        @overridden = overridden
        @confirmed = confirmed
      end

      def present?
        value.present?
      end

      def blank?
        value.blank?
      end

      def calculated?
        source == "calculated"
      end

      def from_settings?
        source == "from_settings"
      end

      def manual?
        source == "manual"
      end

      def overridden?
        !!@overridden
      end

      def confirmed?
        !!@confirmed
      end

      # Delegate element properties
      def name
        element.name
      end

      def type
        element.type
      end

      def label
        element.label
      end

      def label_text
        element.label_text
      end

      def verbose_label
        element.verbose_label
      end

      def verbose_label_text
        element.verbose_label_text
      end

      def short_label
        element.short_label
      end

      def tooltip_label
        element.tooltip_label
      end

      def section
        element.section
      end

      def monetary?
        element.monetary?
      end

      def boolean?
        element.boolean?
      end

      def numeric?
        element.numeric?
      end

      def integer?
        element.integer?
      end

      def string?
        element.string?
      end
    end
  end
end
