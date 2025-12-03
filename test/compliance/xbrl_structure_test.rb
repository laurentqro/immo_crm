# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# XbrlStructureTest validates XML structure, namespaces, contexts, and units.
#
# User Story 4: As a technical validator, I want to verify that generated XBRL
# documents have correct XML structure, so that they can be parsed by validators.
#
# Run: bin/rails test test/compliance/xbrl_structure_test.rb
class XbrlStructureTest < XbrlComplianceTestCase
  def setup
    super
    @submission = submissions(:compliance_test_submission)
    CalculationEngine.new(@submission).populate_submission_values!
    @xbrl_xml = XbrlGenerator.new(@submission).generate
    @xbrl_doc = Nokogiri::XML(@xbrl_xml)
  end

  test "generated XML is well-formed" do
    assert @xbrl_doc.errors.empty?,
      "XML should be well-formed. Errors: #{@xbrl_doc.errors.map(&:message).join(", ")}"
  end

  test "root element is xbrl" do
    root = @xbrl_doc.root
    assert_equal "xbrl", root.name,
      "Root element should be 'xbrl', got '#{root.name}'"
  end

  test "includes required XBRL namespaces" do
    namespaces = @xbrl_doc.root.namespaces

    # Check for essential namespaces
    assert namespaces.value?("http://www.xbrl.org/2003/instance"),
      "Should include XBRL instance namespace"
    assert namespaces.value?("http://www.xbrl.org/2003/linkbase"),
      "Should include XBRL linkbase namespace"
    assert namespaces.value?("http://www.xbrl.org/2003/iso4217"),
      "Should include ISO 4217 currency namespace"
  end

  test "schemaRef points to taxonomy" do
    @xbrl_doc.remove_namespaces!
    schema_ref = @xbrl_doc.at_xpath("//schemaRef")

    assert schema_ref, "Should have schemaRef element"
    href = schema_ref["href"] || schema_ref.attribute_with_ns("href", "http://www.w3.org/1999/xlink")&.value
    assert href&.include?("strix"), "schemaRef should point to strix taxonomy"
  end

  test "entity context exists with RCI identifier" do
    @xbrl_doc.remove_namespaces!
    context = @xbrl_doc.at_xpath("//context[@id='ctx_entity']")

    assert context, "Should have entity context with id='ctx_entity'"

    identifier = context.at_xpath(".//identifier")
    assert identifier, "Context should have identifier"
    assert_equal @organization.rci_number, identifier.text.strip,
      "Identifier should contain organization RCI number"
  end

  test "period is instant with Dec 31 date" do
    @xbrl_doc.remove_namespaces!
    instant = @xbrl_doc.at_xpath("//context[@id='ctx_entity']//instant")

    assert instant, "Should have instant period"
    assert instant.text.include?("-12-31"),
      "Instant should be December 31, got '#{instant.text}'"
  end

  test "EUR unit exists for monetary facts" do
    @xbrl_doc.remove_namespaces!
    eur_unit = @xbrl_doc.at_xpath("//unit[@id='unit_EUR']")

    assert eur_unit, "Should have EUR unit defined"
    # EUR unit contains an element with EUR in its name or the unit itself
    assert eur_unit.to_s.include?("EUR"),
      "EUR unit should reference EUR currency"
  end

  test "pure unit exists for count facts" do
    @xbrl_doc.remove_namespaces!
    pure_unit = @xbrl_doc.at_xpath("//unit[@id='unit_pure']")

    assert pure_unit, "Should have pure unit defined for counts"
  end

  test "all facts have valid contextRef" do
    @xbrl_doc.remove_namespaces!

    # Get all context IDs
    context_ids = @xbrl_doc.xpath("//context").map { |c| c["id"] }.compact.to_set

    # Check each fact has valid contextRef
    facts_without_context = []
    @xbrl_doc.xpath("//*[@contextRef]").each do |fact|
      context_ref = fact["contextRef"]
      unless context_ids.include?(context_ref)
        facts_without_context << "#{fact.name}: #{context_ref}"
      end
    end

    assert facts_without_context.empty?,
      "Facts with invalid contextRef:\n  #{facts_without_context.join("\n  ")}"
  end

  test "monetary facts have unitRef to EUR" do
    @xbrl_doc.remove_namespaces!

    # Known monetary elements
    monetary_elements = %w[a2104B a2105 a2106 a2107 a2202 a2302]

    monetary_elements.each do |element_name|
      fact = @xbrl_doc.at_xpath("//#{element_name}")
      next unless fact # Skip if not present

      unit_ref = fact["unitRef"]
      assert_equal "unit_EUR", unit_ref,
        "Monetary element #{element_name} should have unitRef='unit_EUR', got '#{unit_ref}'"
    end
  end
end
