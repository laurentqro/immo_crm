# frozen_string_literal: true

require "test_helper"

class XbrlGeneratorTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    @submission = submissions(:draft_submission)
    @generator = XbrlGenerator.new(@submission)
  end

  # === Initialization ===

  test "initializes with submission" do
    generator = XbrlGenerator.new(@submission)
    assert_not_nil generator
  end

  # === XML Generation ===

  test "generates valid XML" do
    xml_content = @generator.generate
    assert_not_nil xml_content
    assert_kind_of String, xml_content

    # Should be parseable XML
    doc = Nokogiri::XML(xml_content)
    assert doc.errors.empty?, "XML should be valid: #{doc.errors.join(', ')}"
  end

  test "generates XML with UTF-8 encoding" do
    xml_content = @generator.generate
    assert_includes xml_content, 'encoding="UTF-8"'
  end

  test "generates xbrl root element" do
    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    root = doc.root
    assert_equal "xbrl", root.name
  end

  # === Namespaces ===

  test "includes required XBRL namespaces" do
    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    # Check for standard XBRL namespace
    assert doc.root.namespaces.values.include?("http://www.xbrl.org/2003/instance"),
           "Should include XBRL instance namespace"
  end

  test "includes AMSF taxonomy namespace" do
    xml_content = @generator.generate

    # Should reference the strix taxonomy
    assert_match(/strix/i, xml_content)
  end

  test "includes ISO 4217 currency namespace" do
    xml_content = @generator.generate

    assert_match(/iso4217/i, xml_content)
  end

  # === Schema References ===

  test "includes schema reference to taxonomy" do
    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    schema_refs = doc.xpath("//*[local-name()='schemaRef']")
    assert schema_refs.any?, "Should include schemaRef element"
  end

  # === Contexts ===

  test "generates entity context" do
    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    contexts = doc.xpath("//*[local-name()='context']")
    assert contexts.any?, "Should include context elements"

    # Find the main entity context
    entity_context = contexts.find { |c| c["id"]&.include?("entity") || c["id"]&.include?("ctx") }
    assert entity_context, "Should have an entity context"
  end

  test "context includes organization identifier" do
    xml_content = @generator.generate

    # Should include the RCI number as identifier
    assert_includes xml_content, @organization.rci_number
  end

  test "context includes correct period" do
    xml_content = @generator.generate

    # Should include the submission year
    assert_includes xml_content, @submission.year.to_s
  end

  # === Units ===

  test "generates currency unit for EUR" do
    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    units = doc.xpath("//*[local-name()='unit']")
    assert units.any?, "Should include unit elements"

    # Should have EUR unit
    assert_match(/EUR/i, xml_content)
  end

  test "generates pure unit for counts" do
    xml_content = @generator.generate

    # Should have a pure unit for integer counts
    assert xml_content.match?(/pure/i), "Should have a pure unit for integer counts"
  end

  # === Facts ===

  test "generates facts from submission values" do
    # Ensure submission has values with unique test element name
    SubmissionValue.create!(
      submission: @submission,
      element_name: "x9001",
      value: "42",
      source: "calculated"
    )

    xml_content = @generator.generate

    # Should include the element with its value
    assert_includes xml_content, "x9001"
    assert_includes xml_content, "42"
  end

  test "facts include context reference" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "x9002",
      value: "42",
      source: "calculated"
    )

    xml_content = @generator.generate

    # Facts should reference a context
    assert_match(/contextRef/i, xml_content)
  end

  test "monetary facts include unit reference" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "a2105",  # Purchase value (monetary, not in fixtures for draft_submission)
      value: "1000000.00",
      source: "calculated"
    )

    xml_content = @generator.generate

    # Monetary facts should have unitRef
    assert_match(/unitRef/i, xml_content)
  end

  # === Dimensional Contexts ===

  test "generates country dimension contexts when needed" do
    # Update a1103 with country breakdown as JSON hash
    country_value = @submission.submission_values.find_or_create_by!(element_name: "a1103") do |sv|
      sv.source = "calculated"
    end
    country_value.update!(value: {MC: 10, FR: 5}.to_json)

    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    # Should have dimensional contexts for each country
    contexts = doc.xpath("//*[local-name()='context']")
    mc_context = contexts.find { |c| c["id"] == "ctx_country_MC" }
    fr_context = contexts.find { |c| c["id"] == "ctx_country_FR" }

    assert mc_context, "Should have context for MC country dimension"
    assert fr_context, "Should have context for FR country dimension"
    assert xml_content.include?("CountryDimension"), "Should include CountryDimension elements"
  end

  # === Complete Document Structure ===

  test "generates complete valid XBRL document" do
    # Add various submission values with unique test element names
    SubmissionValue.create!(
      submission: @submission,
      element_name: "x9003",
      value: "42",
      source: "calculated"
    )
    SubmissionValue.create!(
      submission: @submission,
      element_name: "a2106",  # Sale value (monetary, not in draft_submission fixtures)
      value: "1500000.00",
      source: "calculated"
    )

    xml_content = @generator.generate
    doc = Nokogiri::XML(xml_content)

    # Check document structure
    assert doc.root, "Should have root element"
    assert doc.errors.empty?, "Should be valid XML"

    # Should have all major sections
    assert_match(/schemaRef|import/i, xml_content, "Should reference schema")
    assert_match(/context/i, xml_content, "Should have contexts")
    assert_match(/unit/i, xml_content, "Should have units")
  end

  # === File Generation ===

  test "to_file returns filename suggestion" do
    filename = @generator.suggested_filename

    assert_includes filename, "amsf"
    assert_includes filename, @submission.year.to_s
    assert_includes filename, @organization.rci_number
    assert_match(/\.xml$/, filename)
  end

  # === Error Handling ===

  test "handles submission with no values gracefully" do
    empty_submission = Submission.create!(
      organization: @organization,
      year: 2099
    )
    generator = XbrlGenerator.new(empty_submission)

    # Should still generate valid XML structure
    xml_content = generator.generate
    doc = Nokogiri::XML(xml_content)
    assert doc.errors.empty?
  end

  test "handles nil values in submission values" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "a9999",
      value: nil,
      source: "manual"
    )

    # Should not raise an error
    assert_nothing_raised do
      @generator.generate
    end
  end

  # === Content Validation ===

  test "generates facts in correct namespace" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "x9004",
      value: "42",
      source: "calculated"
    )

    xml_content = @generator.generate

    # Element should be in output (strix namespace)
    assert_includes xml_content, "x9004"
  end

  test "boolean values formatted correctly" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "a4102",  # A boolean policy setting (not in fixtures)
      value: "true",
      source: "from_settings"
    )

    xml_content = @generator.generate

    # Boolean should be true/false in XBRL
    assert_match(/true|false/i, xml_content)
  end

  # === Strict Mode Tests ===

  test "strict mode raises XbrlDataError for invalid monetary values" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "a2109B",  # Monetary element
      value: "not-a-number",
      source: "calculated"
    )

    # Strict mode (default in test env) should raise
    generator = XbrlGenerator.new(@submission, strict: true)
    assert_raises(XbrlGenerator::XbrlDataError) do
      generator.generate
    end
  end

  test "lenient mode returns 0.00 for invalid monetary values" do
    SubmissionValue.create!(
      submission: @submission,
      element_name: "a2109B",  # Monetary element
      value: "not-a-number",
      source: "calculated"
    )

    # Lenient mode should not raise
    generator = XbrlGenerator.new(@submission, strict: false)
    xml_content = nil
    assert_nothing_raised do
      xml_content = generator.generate
    end

    # Should contain 0.00 as fallback
    assert_includes xml_content, "0.00"
  end

  test "strict mode defaults to true in non-production environments" do
    generator = XbrlGenerator.new(@submission)
    assert generator.strict, "Strict mode should be true by default in test env"
  end
end
