# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# XbrlDimensionTest validates dimensional contexts for country breakdowns.
#
# User Story 6: As an XBRL validator, I want to verify that country-specific
# facts use correct dimensional contexts, so that data is properly categorized.
#
# Run: bin/rails test test/compliance/xbrl_dimension_test.rb
class XbrlDimensionTest < XbrlComplianceTestCase
  def setup
    super
    @submission = submissions(:compliance_test_submission)
    CalculationEngine.new(@submission).populate_submission_values!
    @xbrl_xml = XbrlGenerator.new(@submission).generate
    @xbrl_doc = parse_xbrl(@xbrl_xml)
  end

  test "generates dimensional context per country" do
    # Get nationality breakdown from engine
    engine = CalculationEngine.new(@submission)
    nationality_breakdown = engine.send(:client_nationality_breakdown)

    # Skip if no nationality data
    skip "No nationality data in submission" if nationality_breakdown.empty?

    context_ids = extract_context_ids(@xbrl_doc)

    nationality_breakdown.keys.each do |element_name|
      country_code = element_name.split("_").last
      expected_context_id = "ctx_country_#{country_code}"

      assert context_ids.include?(expected_context_id),
        "Should have dimensional context for country #{country_code}"
    end
  end

  test "country facts reference correct dimensional context" do
    # Find country-specific elements in the XBRL
    country_elements = @xbrl_doc.xpath("//*[contains(local-name(), 'a1103_')]")

    country_elements.each do |element|
      element_name = element.name
      country_code = element_name.split("_").last
      expected_context = "ctx_country_#{country_code}"

      actual_context = element["contextRef"]
      assert_equal expected_context, actual_context,
        "#{element_name} should reference #{expected_context}, got #{actual_context}"
    end
  end

  test "CountryDimension element present in dimensional contexts" do
    # Check that dimensional contexts include CountryDimension
    dimensional_contexts = @xbrl_doc.xpath("//context[contains(@id, 'ctx_country_')]")

    dimensional_contexts.each do |context|
      dimension = context.at_xpath(".//*[local-name()='CountryDimension']")
      assert dimension,
        "Context #{context["id"]} should include CountryDimension element"
    end
  end

  test "country codes are valid ISO 3166-1 alpha-2" do
    # Get all country codes used in dimensional contexts
    dimensional_contexts = @xbrl_doc.xpath("//context[contains(@id, 'ctx_country_')]")

    # ISO 3166-1 alpha-2 pattern: exactly 2 uppercase letters
    iso_pattern = /\A[A-Z]{2}\z/

    invalid_codes = []
    dimensional_contexts.each do |context|
      context_id = context["id"]
      country_code = context_id.gsub("ctx_country_", "")

      unless country_code.match?(iso_pattern)
        invalid_codes << country_code
      end
    end

    assert invalid_codes.empty?,
      "Invalid country codes found: #{invalid_codes.join(", ")}"
  end

  test "clients without nationality excluded from breakdown" do
    # Verify that blank nationality doesn't create elements
    engine = CalculationEngine.new(@submission)
    breakdown = engine.send(:client_nationality_breakdown)

    # Should not have any elements with blank country code
    blank_elements = breakdown.keys.select { |k| k.match?(/_\z/) }

    assert blank_elements.empty?,
      "Should not have elements for blank nationality: #{blank_elements}"
  end

  test "nationality breakdown sums to expected count" do
    engine = CalculationEngine.new(@submission)
    breakdown = engine.send(:client_nationality_breakdown)
    client_stats = engine.send(:client_statistics)

    total_from_breakdown = breakdown.values.sum
    total_clients = client_stats["a1101"]

    # The breakdown may not equal total if some clients have blank nationality
    assert total_from_breakdown <= total_clients,
      "Nationality breakdown total (#{total_from_breakdown}) should not exceed total clients (#{total_clients})"
  end
end
