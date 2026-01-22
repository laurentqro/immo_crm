# frozen_string_literal: true

module Xbrl
  # ElementManifest defines computation logic for XBRL elements.
  # Works with Taxonomy (metadata) and gem questionnaire for field metadata.
  #
  # This is a thin layer that:
  # 1. Identifies which elements are computable vs manual
  # 2. Provides a consistent interface for value retrieval
  # 3. Combines taxonomy metadata with stored submission values
  # 4. Provides gem questionnaire access for field lookup and visibility
  #
  # Usage:
  #   manifest = Xbrl::ElementManifest.new(submission)
  #   manifest.value_for("a1101")        # => "42"
  #   manifest.element_with_value("a1101") # => ElementValue
  #   manifest.field(:a1101)             # => AmsfSurvey::Field (via gem)
  #   manifest.all_fields                # => Array<AmsfSurvey::Field>
  #
  class ElementManifest
    attr_reader :submission

    def initialize(submission)
      @submission = submission
      @stored_values = submission.submission_values.index_by(&:element_name)
    end

    # === Gem Questionnaire Access ===

    # Get field by ID from gem questionnaire
    # Returns nil if field not found or gem not available for this year
    #
    # @param field_id [Symbol, String] the field identifier
    # @return [AmsfSurvey::Field, nil] the field or nil
    def field(field_id)
      return nil unless questionnaire

      questionnaire.field(field_id.to_sym)
    end

    # Get all fields from gem questionnaire
    # Returns empty array if gem not available for this year
    #
    # @return [Array<AmsfSurvey::Field>]
    def all_fields
      return [] unless questionnaire

      questionnaire.fields
    end

    # Get fields grouped by section from gem questionnaire
    # Returns sections as {section_name => [fields]}
    #
    # @return [Hash{String => Array<AmsfSurvey::Field>}]
    def fields_by_section
      return {} unless questionnaire

      questionnaire.sections.each_with_object({}) do |section, hash|
        hash[section.name] = section.fields
      end
    end

    # Check if a field is visible based on gate dependencies
    #
    # @param field_id [Symbol, String] the field identifier
    # @param data [Hash] current submission data for gate evaluation
    # @return [Boolean] true if field is visible
    def field_visible?(field_id, data = gate_data)
      f = field(field_id)
      return true unless f # Default to visible if field not found

      f.visible?(data)
    end

    # Get current submission data for gate field evaluation
    # Returns a hash of field_id => value for all stored values
    #
    # @return [Hash{Symbol => Object}]
    def gate_data
      @gate_data ||= @stored_values.transform_keys(&:to_sym).transform_values(&:value)
    end

    # Get the gem questionnaire for this submission's year
    # Returns nil if the year is not supported by the gem
    #
    # @return [AmsfSurvey::Questionnaire, nil]
    def questionnaire
      return @questionnaire if defined?(@questionnaire)

      @questionnaire = begin
        if gem_supported_year?
          AmsfSurvey.questionnaire(industry: :real_estate, year: submission.year)
        end
      rescue AmsfSurvey::TaxonomyLoadError
        nil
      end
    end

    private

    def gem_supported_year?
      AmsfSurvey.registered?(:real_estate) &&
        AmsfSurvey.supported_years(:real_estate).include?(submission.year)
    end

    public

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
        confirmed: sv&.confirmed?,
        needs_review: sv&.needs_review? || false
      )
    end

    # Get all elements with their values, in presentation order.
    # Only returns elements that have actual values stored.
    # Memoized since @stored_values doesn't change after initialization.
    def all_elements_with_values
      @all_elements_with_values ||= @stored_values.keys.filter_map do |element_name|
        element_with_value(element_name)
      end.sort_by { |ev| ev.element.order }.freeze
    end

    # Get elements grouped by section with their values
    def elements_by_section
      all_elements_with_values.group_by { |ev| ev.element.section }
    end

    # Value object combining element metadata with submission value
    class ElementValue
      attr_reader :element, :value, :source, :overridden, :confirmed, :needs_review

      def initialize(element:, value:, source:, overridden:, confirmed:, needs_review: false)
        @element = element
        @value = value
        @source = source
        @overridden = overridden
        @confirmed = confirmed
        @needs_review = needs_review
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

      def needs_review?
        !!@needs_review
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

      def dimensional?
        element.dimensional?
      end

      def type_label
        element.type_label
      end

      # Parse dimensional value as hash (country code => count)
      # Returns empty hash if parsing fails or not dimensional
      def dimensional_breakdown
        return {} unless dimensional? && value.present?

        JSON.parse(value)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
