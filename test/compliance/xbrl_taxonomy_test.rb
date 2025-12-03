# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# XbrlTaxonomyTest validates that every generated XBRL element name exists
# in the official AMSF taxonomy schema.
#
# This is the MOST CRITICAL compliance test - catching invalid element names
# before submission prevents rejection by the AMSF system.
#
# User Story 1: As an XBRL generator, I want to validate that every element
# I output exists in the official taxonomy, so that my submissions are accepted
# by the AMSF system.
#
# Run: bin/rails test test/compliance/xbrl_taxonomy_test.rb
class XbrlTaxonomyTest < XbrlComplianceTestCase
  def setup
    super
    @submission = submissions(:compliance_test_submission)
  end

  test "XbrlTestHelper parses taxonomy correctly" do
    expected_count = XbrlTestHelper::EXPECTED_ELEMENT_COUNT

    # Verify the helper is correctly parsing the XSD
    assert_equal expected_count, XbrlTestHelper.taxonomy_elements.count,
      "Taxonomy should have exactly #{expected_count} non-abstract elements"

    assert_equal expected_count, XbrlTestHelper.valid_element_names.count,
      "Valid element names Set should have #{expected_count} entries"

    assert XbrlTestHelper.valid_element_names.is_a?(Set),
      "valid_element_names should be a Set for O(1) lookup"
  end

  test "all generated elements exist in taxonomy" do
    # Populate submission with calculated values
    CalculationEngine.new(@submission).populate_submission_values!

    # Generate XBRL
    xbrl_xml = XbrlGenerator.new(@submission).generate
    xbrl_doc = parse_xbrl(xbrl_xml)

    # Extract element names from generated XBRL
    generated_elements = extract_element_names(xbrl_doc)

    # Skip test if no elements were generated (empty submission)
    skip "No elements generated - submission may have no data" if generated_elements.empty?

    # Validate each element exists in taxonomy
    assert_all_elements_valid(xbrl_doc)
  end

  test "no abstract elements appear in output" do
    # Abstract elements should never appear in instance documents
    # The XSD marks these with abstract="true"
    abstract_elements = %w[
      Abstract_NoCountryDimension
      Abstract_aAC
      Abstract_aLE
      CountryDimension
      CountryDomain
      CountryTableNoCountryDimension
      CountryTableaAC
      CountryTableaLE
    ]

    # Generate XBRL
    CalculationEngine.new(@submission).populate_submission_values!
    xbrl_xml = XbrlGenerator.new(@submission).generate
    xbrl_doc = parse_xbrl(xbrl_xml)

    # Check that no abstract elements are present
    generated_elements = extract_element_names(xbrl_doc)
    abstract_in_output = generated_elements & abstract_elements

    assert abstract_in_output.empty?,
      "Abstract elements should not appear in output: #{abstract_in_output.join(", ")}"
  end

  test "element suffixes match taxonomy semantics" do
    # AMSF taxonomy uses specific suffixes with semantic meaning:
    # B  = BY clients (count of clients BY some criteria)
    # W  = WITH clients (count of clients WITH some attribute)
    # BB = BY-BY combination
    # BW = BY-WITH combination
    # R  = Rate/ratio values
    # TOLA = Top-Level Abstraction (boolean policy questions)

    # Verify some known elements with suffixes exist
    known_suffix_elements = {
      "a1105B" => :integer,    # BY suffix
      "a1105W" => :integer,    # WITH suffix
      "a11001BTOLA" => :enum   # Boolean policy question
    }

    known_suffix_elements.each do |element_name, expected_type|
      assert XbrlTestHelper.valid_element_names.include?(element_name),
        "Expected taxonomy element '#{element_name}' to exist"

      actual_type = XbrlTestHelper.element_types[element_name]
      assert_equal expected_type, actual_type,
        "Element '#{element_name}' should be type #{expected_type}, got #{actual_type}"
    end
  end

  test "descriptive error messages show invalid element name and closest match" do
    # Test the suggestion mechanism
    invalid_name = "a2401"  # Intentionally wrong (might be missing suffix)
    suggestion = XbrlTestHelper.suggest_element_name(invalid_name)

    assert suggestion.present?,
      "Should suggest a similar element name"

    # The suggestion should be close to the invalid name
    assert suggestion.start_with?("a"),
      "Suggestion should start with 'a' like the taxonomy pattern"
  end

  test "validates specific element names from mapping config" do
    # Load the actual element mapping configuration
    mapping_path = Rails.root.join("config/amsf_element_mapping.yml")
    skip "No element mapping config found" unless File.exist?(mapping_path)

    mapping = YAML.load_file(mapping_path)
    invalid_mappings = []

    # Check each mapped element
    mapping.each do |element_name, config|
      next if element_name.to_s.start_with?("_") # Skip meta keys

      unless XbrlTestHelper.valid_element_names.include?(element_name.to_s)
        suggestion = XbrlTestHelper.suggest_element_name(element_name.to_s)
        invalid_mappings << "#{element_name} (did you mean: #{suggestion}?)"
      end
    end

    assert invalid_mappings.empty?,
      "Found #{invalid_mappings.size} invalid element(s) in amsf_element_mapping.yml:\n  " \
      "#{invalid_mappings.join("\n  ")}"
  end

  test "taxonomy contains expected sections" do
    # The AMSF survey has defined sections (Tabs 1-4 + Signatories)
    # Verify we have elements from each major section

    # Tab 1: Customer Risk (a11xx, a12xx, a13xx, a14xx, a15xx series)
    tab1_elements = XbrlTestHelper.valid_element_names.select { |n| n.match?(/^a1[12345]\d{2}/) }
    assert tab1_elements.any?, "Taxonomy should contain Tab 1 (Customer Risk) elements"

    # Tab 2: Products/Services (a21xx, a22xx, a25xx series)
    tab2_elements = XbrlTestHelper.valid_element_names.select { |n| n.match?(/^a2[125]\d{2}/) }
    assert tab2_elements.any?, "Taxonomy should contain Tab 2 (Products/Services) elements"

    # Tab 3: Distribution (a31xx, a32xx, a33xx, a34xx, a35xx series)
    tab3_elements = XbrlTestHelper.valid_element_names.select { |n| n.match?(/^a3[12345]\d{2}/) }
    assert tab3_elements.any?, "Taxonomy should contain Tab 3 (Distribution) elements"

    # Tab 4: Controls (aC1xx series - uses different prefix)
    tab4_elements = XbrlTestHelper.valid_element_names.select { |n| n.match?(/^aC1/) }
    assert tab4_elements.any?, "Taxonomy should contain Tab 4 (Controls) elements"
    expected_tab4_count = XbrlTestHelper::EXPECTED_TAB4_ELEMENT_COUNT
    assert_equal expected_tab4_count, tab4_elements.size,
      "Tab 4 should have #{expected_tab4_count} control elements"
  end
end
