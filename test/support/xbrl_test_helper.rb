# frozen_string_literal: true

# XbrlTestHelper provides shared utilities for XBRL compliance testing.
#
# This module parses the authoritative AMSF taxonomy XSD once at class load
# and memoizes the results for O(1) element name lookups during tests.
#
# Class methods (called once, cached):
#   - taxonomy_elements: All 323 non-abstract elements from XSD
#   - valid_element_names: Set of element names for fast lookup
#   - element_types: Hash mapping element names to type symbols
#   - enum_values: Hash mapping enum element names to allowed values
#
# Instance methods (for test classes):
#   - parse_xbrl: Parse XBRL XML string into Nokogiri document
#   - extract_element_names: Get all element names from XBRL document
#   - extract_element_value: Get value of specific element
module XbrlTestHelper
  XSD_PATH = Rails.root.join("docs/strix_Real_Estate_AML_CFT_survey_2025.xsd")
  STRIX_NAMESPACE = "https://amlcft.amsf.mc/dcm/DTS/strix_Real_Estate_AML_CFT_survey_2025/fr"

  class << self
    # Returns Array of element definitions from XSD.
    # Each element: { name:, id:, type:, allowed_values: }
    #
    # @return [Array<Hash>] Array of element definition hashes
    def taxonomy_elements
      @taxonomy_elements ||= parse_xsd_elements
    end

    # Returns Set of valid element names for O(1) lookup.
    #
    # @return [Set<String>] Set of element names
    def valid_element_names
      @valid_element_names ||= taxonomy_elements.map { |e| e[:name] }.to_set
    end

    # Returns Hash mapping element name to type symbol.
    # Types: :integer, :monetary, :string, :enum
    #
    # @return [Hash<String, Symbol>] Element name to type mapping
    def element_types
      @element_types ||= taxonomy_elements.each_with_object({}) do |element, hash|
        hash[element[:name]] = element[:type]
      end
    end

    # Returns Hash mapping enum element names to allowed values.
    # Only includes elements with enumeration restrictions.
    #
    # @return [Hash<String, Array<String>>] Element name to allowed values
    def enum_values
      @enum_values ||= taxonomy_elements
        .select { |e| e[:type] == :enum }
        .each_with_object({}) do |element, hash|
          hash[element[:name]] = element[:allowed_values]
        end
    end

    # Suggests the closest matching element name for typo detection.
    #
    # @param invalid_name [String] The invalid element name
    # @return [String, nil] Closest match or nil if no close match
    def suggest_element_name(invalid_name)
      return nil if invalid_name.nil? || invalid_name.empty?

      valid_element_names.min_by do |valid_name|
        levenshtein_distance(invalid_name, valid_name)
      end
    end

    private

    def parse_xsd_elements
      doc = Nokogiri::XML(File.read(XSD_PATH))
      doc.remove_namespaces!

      doc.xpath("//element[@abstract='false']").map do |el|
        {
          name: el["name"],
          id: el["id"],
          type: determine_type(el),
          allowed_values: extract_enum_values(el)
        }
      end
    end

    def determine_type(element_node)
      type_attr = element_node["type"]

      return :integer if type_attr&.include?("integerItemType")
      return :monetary if type_attr&.include?("monetaryItemType")
      return :string if type_attr&.include?("stringItemType")

      # Check for inline enumeration (Oui/Non booleans)
      return :enum if element_node.xpath(".//enumeration").any?

      :unknown
    end

    def extract_enum_values(element_node)
      enumerations = element_node.xpath(".//enumeration")
      return [] if enumerations.empty?

      enumerations.map { |e| e["value"] }
    end

    def levenshtein_distance(s1, s2)
      m = s1.length
      n = s2.length
      return n if m.zero?
      return m if n.zero?

      d = Array.new(m + 1) { Array.new(n + 1) }

      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }

      (1..m).each do |i|
        (1..n).each do |j|
          cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1
          d[i][j] = [
            d[i - 1][j] + 1,      # deletion
            d[i][j - 1] + 1,      # insertion
            d[i - 1][j - 1] + cost # substitution
          ].min
        end
      end

      d[m][n]
    end
  end

  # === Instance Methods (for test classes) ===

  # Parse generated XBRL XML string into Nokogiri document.
  #
  # @param xml_string [String] XBRL XML content
  # @return [Nokogiri::XML::Document] Parsed document with namespaces preserved
  def parse_xbrl(xml_string)
    doc = Nokogiri::XML(xml_string)
    doc.remove_namespaces! # Simplify XPath queries
    doc
  end

  # Extract all element names from generated XBRL document.
  # Only returns strix namespace elements (the taxonomy elements).
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @return [Array<String>] Array of element names
  def extract_element_names(xbrl_doc)
    # Find all elements that look like taxonomy elements (a#### pattern)
    xbrl_doc.xpath("//*[starts-with(local-name(), 'a')]").map(&:name).uniq
  end

  # Get value of specific element from XBRL document.
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @param element_name [String] Element name to find
  # @return [String, nil] Element text content or nil if not found
  def extract_element_value(xbrl_doc, element_name)
    element = xbrl_doc.at_xpath("//#{element_name}")
    element&.text
  end

  # Get all values for elements with the same name (for dimensional elements).
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @param element_name [String] Element name to find
  # @return [Array<Hash>] Array of { value:, context_ref:, unit_ref: }
  def extract_all_element_values(xbrl_doc, element_name)
    xbrl_doc.xpath("//#{element_name}").map do |el|
      {
        value: el.text,
        context_ref: el["contextRef"],
        unit_ref: el["unitRef"]
      }
    end
  end

  # Validate element has correct contextRef attribute.
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @param element_name [String] Element name to check
  # @return [Boolean] True if element has valid contextRef
  def has_valid_context_ref?(xbrl_doc, element_name)
    element = xbrl_doc.at_xpath("//#{element_name}")
    return false unless element

    context_ref = element["contextRef"]
    return false if context_ref.nil? || context_ref.empty?

    # Check that the referenced context exists
    xbrl_doc.at_xpath("//context[@id='#{context_ref}']").present?
  end

  # Validate element has correct unitRef attribute for monetary/integer types.
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @param element_name [String] Element name to check
  # @param expected_unit [String] Expected unit ID (e.g., "EUR", "pure")
  # @return [Boolean] True if element has expected unitRef
  def has_valid_unit_ref?(xbrl_doc, element_name, expected_unit)
    element = xbrl_doc.at_xpath("//#{element_name}")
    return false unless element

    unit_ref = element["unitRef"]
    return false if unit_ref.nil?

    # Check that the referenced unit exists and matches expected
    unit_ref == expected_unit && xbrl_doc.at_xpath("//unit[@id='#{expected_unit}']").present?
  end

  # Get all contexts defined in the XBRL document.
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @return [Array<String>] Array of context IDs
  def extract_context_ids(xbrl_doc)
    xbrl_doc.xpath("//context").map { |c| c["id"] }
  end

  # Get all units defined in the XBRL document.
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  # @return [Array<String>] Array of unit IDs
  def extract_unit_ids(xbrl_doc)
    xbrl_doc.xpath("//unit").map { |u| u["id"] }
  end
end
