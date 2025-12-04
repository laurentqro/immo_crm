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

    # Get all elements with their values, in presentation order
    def all_elements_with_values
      Taxonomy.elements.map do |element|
        element_with_value(element.name)
      end.compact
    end

    # Get elements grouped by section with their values
    def elements_by_section
      all_elements_with_values.group_by { |ev| ev.element.section }
    end

    # Format a value according to its element type
    def formatted_value(element_name, format: :display)
      ev = element_with_value(element_name)
      return nil unless ev&.value.present?

      case format
      when :xbrl
        format_for_xbrl(ev.value, ev.element)
      when :html
        format_for_html(ev.value, ev.element)
      when :display
        format_for_display(ev.value, ev.element)
      else
        ev.value
      end
    end

    private

    def format_for_xbrl(value, element)
      case element.type
      when :boolean
        value.to_s.downcase.in?(%w[true 1 yes oui]) ? "Oui" : "Non"
      when :monetary
        format("%.2f", BigDecimal(value.to_s))
      when :integer
        value.to_i.to_s
      else
        value.to_s
      end
    rescue ArgumentError
      value.to_s
    end

    def format_for_html(value, element)
      case element.type
      when :boolean
        value.to_s.downcase.in?(%w[true 1 yes oui]) ? "Yes" : "No"
      when :monetary
        ActionController::Base.helpers.number_to_currency(value, unit: "€", format: "%n %u")
      when :integer
        ActionController::Base.helpers.number_with_delimiter(value.to_i)
      else
        value.to_s
      end
    rescue ArgumentError
      value.to_s
    end

    def format_for_display(value, element)
      format_for_html(value, element)
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
