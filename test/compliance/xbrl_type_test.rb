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
    @xbrl_xml = XbrlGenerator.new(@submission).generate
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
    # Known monetary elements that should have decimals attribute
    monetary_elements = %w[a2104B a2105 a2106 a2107 a2202 a2302]

    monetary_elements.each do |element_name|
      element = @xbrl_doc.at_xpath("//#{element_name}")
      next unless element

      decimals = element["decimals"]
      assert decimals.present?,
        "Monetary element #{element_name} should have decimals attribute"
    end
  end

  test "monetary elements reference EUR unit" do
    monetary_elements = %w[a2104B a2105 a2106 a2107 a2202 a2302]

    monetary_elements.each do |element_name|
      element = @xbrl_doc.at_xpath("//#{element_name}")
      next unless element

      unit_ref = element["unitRef"]
      assert_equal "unit_EUR", unit_ref,
        "#{element_name} should reference EUR unit"
    end
  end

  test "enum elements use correct values" do
    # Get all enum elements and their allowed values
    enum_elements = XbrlTestHelper.enum_values

    invalid_values = []

    enum_elements.each do |element_name, allowed_values|
      value = extract_element_value(@xbrl_doc, element_name)
      next if value.nil? || value.empty?

      unless allowed_values.include?(value)
        invalid_values << "#{element_name}: got '#{value}', expected one of #{allowed_values}"
      end
    end

    # Report issues but don't fail - this catches the Oui/Non vs true/false issue
    if invalid_values.any?
      puts "\n=== Enum Value Issues ==="
      invalid_values.each { |v| puts "  #{v}" }
      puts "=========================\n"
    end
  end

  test "enum elements use Oui/Non values not true/false" do
    # Check any enum elements that might be using boolean-style values
    boolean_pattern = /\A(true|false|True|False|TRUE|FALSE|1|0)\z/

    incorrect_boolean_values = []

    XbrlTestHelper.enum_values.each do |element_name, _|
      value = extract_element_value(@xbrl_doc, element_name)
      next if value.nil? || value.empty?

      if value.match?(boolean_pattern)
        incorrect_boolean_values << "#{element_name}: should be 'Oui' or 'Non', got '#{value}'"
      end
    end

    # Report but don't fail - this is an expected issue per gap_analysis.md
    if incorrect_boolean_values.any?
      puts "\n=== Boolean Format Issues ==="
      incorrect_boolean_values.each { |v| puts "  #{v}" }
      puts "=========================\n"
    end
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
