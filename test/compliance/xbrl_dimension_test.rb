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
    # Get nationality breakdown from engine (now returns {"a1103" => {FR: count, ...}})
    engine = CalculationEngine.new(@submission)
    nationality_breakdown = engine.send(:client_nationality_breakdown)

    # Skip if no nationality data
    skip "No nationality data in submission" if nationality_breakdown.empty? || !nationality_breakdown["a1103"]

    country_data = nationality_breakdown["a1103"]
    context_ids = extract_context_ids(@xbrl_doc)

    country_data.keys.each do |country_code|
      expected_context_id = "ctx_country_#{country_code}"

      assert context_ids.include?(expected_context_id),
        "Should have dimensional context for country #{country_code}"
    end
  end

  test "country facts reference correct dimensional context" do
    # Find a1103 elements in the XBRL (now uses single element name with dimensional contexts)
    a1103_elements = @xbrl_doc.xpath("//*[local-name()='a1103']")

    # Skip if no a1103 elements
    skip "No a1103 elements in XBRL" if a1103_elements.empty?

    a1103_elements.each do |element|
      context_ref = element["contextRef"]

      # Should reference a country-specific context
      assert context_ref&.start_with?("ctx_country_"),
        "a1103 element should reference country-specific context, got #{context_ref}"
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

    # Skip if no nationality data
    return if breakdown.empty? || !breakdown["a1103"]

    country_data = breakdown["a1103"]

    # Should not have any elements with blank country code
    blank_elements = country_data.keys.select { |k| k.to_s.strip.empty? }

    assert blank_elements.empty?,
      "Should not have elements for blank nationality: #{blank_elements}"
  end

  test "nationality breakdown sums to expected count" do
    engine = CalculationEngine.new(@submission)
    breakdown = engine.send(:client_nationality_breakdown)
    client_stats = engine.send(:client_statistics)

    # Skip if no nationality data
    return if breakdown.empty? || !breakdown["a1103"]

    country_data = breakdown["a1103"]
    total_from_breakdown = country_data.values.sum
    total_clients = client_stats["a1101"]

    # The breakdown may not equal total if some clients have blank nationality
    assert total_from_breakdown <= total_clients,
      "Nationality breakdown total (#{total_from_breakdown}) should not exceed total clients (#{total_clients})"
  end
end
