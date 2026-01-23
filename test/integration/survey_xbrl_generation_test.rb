# frozen_string_literal: true

require "test_helper"
require "nokogiri"

# Integration test for Survey PORO XBRL generation.
#
# This test verifies that the Survey PORO can generate valid XBRL
# from end to end, including:
# - Entity identification
# - Period information
# - Field values populated from organization data
#
class SurveyXbrlGenerationTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    @survey = Survey.new(organization: @organization, year: 2025)
  end

  # === Core XBRL Generation Tests ===

  test "to_xbrl generates valid XML" do
    xbrl = @survey.to_xbrl

    # Parse as XML - should not raise
    doc = Nokogiri::XML(xbrl)

    # Check for parsing errors
    assert doc.errors.empty?, "XBRL should be valid XML. Errors: #{doc.errors.map(&:message).join(", ")}"
  end

  test "to_xbrl contains XML declaration" do
    xbrl = @survey.to_xbrl

    assert_match(/\A<\?xml version="1\.0"/, xbrl, "XBRL should start with XML declaration")
  end

  test "to_xbrl contains xbrl root element" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    root = doc.at_xpath("//xbrl")
    assert root.present?, "XBRL should have xbrl root element"
  end

  # === Entity Identification Tests ===

  test "to_xbrl contains entity identifier with RCI number" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    identifier = doc.at_xpath("//entity/identifier")

    assert identifier.present?, "XBRL should contain entity identifier"
    assert_equal @organization.rci_number, identifier.text.strip,
      "Entity identifier should be organization's RCI number"
  end

  test "to_xbrl entity identifier has scheme attribute" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    identifier = doc.at_xpath("//entity/identifier")

    assert identifier["scheme"].present?, "Entity identifier should have scheme attribute"
  end

  # === Period Tests ===

  test "to_xbrl contains period with instant date" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    instant = doc.at_xpath("//period/instant")

    assert instant.present?, "XBRL should contain period instant"
    assert_equal "2025-12-31", instant.text.strip,
      "Period instant should be December 31st of survey year"
  end

  # === Context Structure Tests ===

  test "to_xbrl contains at least one context element" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    contexts = doc.xpath("//context")

    assert contexts.any?, "XBRL should contain at least one context element"
  end

  test "to_xbrl context has required structure" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    context = doc.at_xpath("//context")

    assert context["id"].present?, "Context should have id attribute"
    assert context.at_xpath(".//entity"), "Context should have entity element"
    assert context.at_xpath(".//period"), "Context should have period element"
  end

  # === Field Value Tests ===

  test "to_xbrl contains fact elements with contextRef" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    # Find elements with contextRef attribute (these are XBRL facts)
    facts = doc.xpath("//*[@contextRef]")

    assert facts.any?, "XBRL should contain at least one fact element with contextRef"
  end

  test "to_xbrl fact contextRef references valid context" do
    xbrl = @survey.to_xbrl
    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    # Get all context IDs
    context_ids = doc.xpath("//context/@id").map(&:value)
    assert context_ids.any?, "Should have at least one context"

    # Get all fact contextRefs
    fact_context_refs = doc.xpath("//*[@contextRef]/@contextRef").map(&:value).uniq

    # Each fact contextRef should reference a valid context
    fact_context_refs.each do |ref|
      assert_includes context_ids, ref, "Fact contextRef '#{ref}' should reference a valid context"
    end
  end

  # === Namespace Tests ===

  test "to_xbrl declares required XBRL namespaces" do
    xbrl = @survey.to_xbrl

    # Check for essential namespace declarations
    assert_match(/xmlns.*xbrl/i, xbrl, "XBRL should declare xbrl namespace")
  end

  # === Full Round-Trip Test ===

  test "full XBRL generation round-trip" do
    # This test verifies the complete flow from Survey creation to XBRL output

    # 1. Create Survey with test organization
    survey = Survey.new(organization: @organization, year: 2025)

    # 2. Generate XBRL
    xbrl = survey.to_xbrl

    # 3. Parse as XML
    doc = Nokogiri::XML(xbrl)
    assert doc.errors.empty?, "Generated XBRL must be valid XML"

    doc.remove_namespaces!

    # 4. Verify entity information
    identifier = doc.at_xpath("//entity/identifier")
    assert_equal @organization.rci_number, identifier&.text&.strip

    # 5. Verify period information
    instant = doc.at_xpath("//period/instant")
    assert_equal "2025-12-31", instant&.text&.strip

    # 6. Verify at least one fact is present
    facts = doc.xpath("//*[@contextRef]")
    assert facts.any?, "XBRL should contain field values"
  end

  # === Year Variation Tests ===

  test "survey period reflects the specified year" do
    # Use 2025 which is a supported year
    survey = Survey.new(organization: @organization, year: 2025)
    xbrl = survey.to_xbrl

    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    instant = doc.at_xpath("//period/instant")
    assert_equal "2025-12-31", instant&.text&.strip,
      "Period should reflect the survey year"
  end

  test "unsupported year raises TaxonomyLoadError" do
    # Year 2024 is not supported - verify graceful error handling
    survey_2024 = Survey.new(organization: @organization, year: 2024)

    assert_raises(AmsfSurvey::TaxonomyLoadError) do
      survey_2024.to_xbrl
    end
  end

  # === Different Organization Tests ===

  test "different organization produces correct entity identifier" do
    other_org = organizations(:two)
    survey = Survey.new(organization: other_org, year: 2025)
    xbrl = survey.to_xbrl

    doc = Nokogiri::XML(xbrl)
    doc.remove_namespaces!

    identifier = doc.at_xpath("//entity/identifier")
    assert_equal other_org.rci_number, identifier&.text&.strip,
      "Entity identifier should be the organization's RCI number"
  end

  private

  # Helper to extract facts from XBRL (field_id => value)
  def extract_facts_from_xbrl(xml_string)
    doc = Nokogiri::XML(xml_string)
    doc.remove_namespaces!

    facts = {}
    doc.xpath("//*[@contextRef]").each do |node|
      field_id = node.name
      facts[field_id] = node.text.strip
    end
    facts
  end

  # Helper to extract context info from XBRL
  def extract_context_from_xbrl(xml_string)
    doc = Nokogiri::XML(xml_string)
    doc.remove_namespaces!

    context_node = doc.at_xpath("//context")
    return {} unless context_node

    {
      entity_id: context_node.at_xpath(".//identifier")&.text,
      period: context_node.at_xpath(".//instant")&.text,
      context_id: context_node["id"]
    }
  end
end
