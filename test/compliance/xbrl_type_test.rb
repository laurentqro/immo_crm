# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# XbrlTypeTest validates element values match taxonomy-defined types.
#
# User Story 5: As an XBRL validator, I want to verify that element values
# conform to their defined types, so that values are correctly formatted.
#
# Run: bin/rails test test/compliance/xbrl_type_test.rb
class XbrlTypeTest < XbrlComplianceTestCase
  def setup
    super
    @submission = submissions(:compliance_test_submission)
    CalculationEngine.new(@submission).populate_submission_values!
    @xbrl_xml = SubmissionRenderer.new(@submission).to_xbrl
    @xbrl_doc = parse_xbrl(@xbrl_xml)
  end

  test "integer elements have whole number values" do
    # Get all integer-type elements from taxonomy
    integer_elements = XbrlTestHelper.element_types.select { |_, type| type == :integer }.keys

    invalid_values = []

    integer_elements.each do |element_name|
      value = extract_element_value(@xbrl_doc, element_name)
      next if value.nil? || value.empty?

      # Check it's a valid integer (no decimal point with non-zero fraction)
      unless value.match?(/\A-?\d+\z/) || value.match?(/\A-?\d+\.0+\z/)
        invalid_values << "#{element_name}: '#{value}'"
      end
    end

    assert invalid_values.empty?,
      "Integer elements should have whole number values:\n  #{invalid_values.join("\n  ")}"
  end

  test "monetary elements have decimals attribute" do
    # Monetary elements that should have decimals attribute
    monetary_elements = %w[a2109B a2102BB a2105BB]

    monetary_elements.each do |element_name|
      element = @xbrl_doc.at_xpath("//#{element_name}")
      next unless element

      decimals = element["decimals"]
      assert decimals.present?,
        "Monetary element #{element_name} should have decimals attribute"
    end
  end

  test "monetary elements reference EUR unit" do
    monetary_elements = %w[a2109B a2102BB a2105BB]

    monetary_elements.each do |element_name|
      element = @xbrl_doc.at_xpath("//#{element_name}")
      next unless element

      unit_ref = element["unitRef"]
      assert_equal "unit_EUR", unit_ref,
        "#{element_name} should reference EUR unit"
    end
  end

  test "enum elements use correct values" do
    # Check only Oui/Non boolean elements
    oui_non_elements = XbrlTestHelper.enum_values.select do |_, allowed|
      allowed.sort == %w[Non Oui]
    end

    invalid_values = []

    oui_non_elements.each do |element_name, allowed_values|
      value = extract_element_value(@xbrl_doc, element_name)
      next if value.nil? || value.empty?

      unless allowed_values.include?(value)
        invalid_values << "#{element_name}: got '#{value}', expected one of #{allowed_values}"
      end
    end

    assert invalid_values.empty?,
      "Boolean elements should use Oui/Non values:\n  #{invalid_values.join("\n  ")}"
  end

  test "enum elements use Oui/Non values not true/false" do
    # Check that Oui/Non boolean elements don't use English boolean format
    boolean_pattern = /\A(true|false|True|False|TRUE|FALSE|1|0)\z/

    # Filter to actual Oui/Non elements only
    oui_non_elements = XbrlTestHelper.enum_values.select do |_, allowed|
      allowed.sort == %w[Non Oui]
    end

    incorrect_boolean_values = []

    oui_non_elements.each do |element_name, _|
      value = extract_element_value(@xbrl_doc, element_name)
      next if value.nil? || value.empty?

      if value.match?(boolean_pattern)
        incorrect_boolean_values << "#{element_name}: should be 'Oui' or 'Non', got '#{value}'"
      end
    end

    assert incorrect_boolean_values.empty?,
      "Boolean elements should use French format (Oui/Non), not English:\n  #{incorrect_boolean_values.join("\n  ")}"
  end

  test "element type categorization is correct" do
    # Verify our type detection is working
    assert_equal :integer, XbrlTestHelper.element_types["a1101"],
      "a1101 (client count) should be integer type"

    assert_equal :enum, XbrlTestHelper.element_types["a11001BTOLA"],
      "a11001BTOLA should be enum type"

    assert_equal :string, XbrlTestHelper.element_types["a11006"],
      "a11006 should be string type"
  end

  test "most enum elements have Oui/Non values" do
    # Most enum elements in this taxonomy use Oui/Non
    # Some use country lists or other enumerations
    oui_non_elements = XbrlTestHelper.enum_values.select do |_, allowed|
      allowed.sort == %w[Non Oui]
    end

    # The taxonomy has 135 enum elements, most should be Oui/Non
    assert oui_non_elements.size > 100,
      "Most enum elements should be Oui/Non type (found #{oui_non_elements.size})"
  end
end
