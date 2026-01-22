# frozen_string_literal: true

require "test_helper"
require "nokogiri"

# Integration tests for AMSF Survey gem migration.
#
# These tests ensure XBRL output parity between the old ERB template and
# the new gem-based generation. The strategy is:
#
# 1. Generate baseline XBRL with OLD code (current ERB template)
# 2. Generate comparison XBRL with NEW code (gem generator)
# 3. Compare normalized XML to verify semantic equivalence
#
# Key differences to account for:
# - Entity scheme: ERB uses http://amsf.mc/rci, gem uses https://amlcft.amsf.mc
# - Context IDs: May differ but must be consistent within document
# - Units: ERB includes explicit unit elements, gem may not
# - Field ordering: May differ but all required fields must be present
#
class AmsfGemMigrationTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    # Create a test submission for the comparison
    @submission = Submission.find_or_create_by!(organization: @organization, year: 2025)

    # Populate some test values
    populate_test_values(@submission)
  end

  # === Phase 2: Comparison Test Infrastructure ===

  test "normalize_xbrl removes whitespace differences" do
    xml1 = "<root>  <child>  value  </child>  </root>"
    xml2 = "<root>\n  <child>\n    value\n  </child>\n</root>"

    assert_equal normalize_xbrl(xml1), normalize_xbrl(xml2)
  end

  test "normalize_xbrl preserves element content" do
    xml = "<strix:a1101 contextRef='ctx'>42</strix:a1101>"
    normalized = normalize_xbrl(xml)

    assert_includes normalized, "a1101"
    assert_includes normalized, "42"
  end

  test "extract_facts_from_xbrl returns fact elements" do
    xml = <<~XML
      <?xml version="1.0"?>
      <xbrl xmlns:strix="http://example.com">
        <context id="ctx"/>
        <strix:a1101 contextRef="ctx">42</strix:a1101>
        <strix:a1102 contextRef="ctx">100</strix:a1102>
      </xbrl>
    XML

    facts = extract_facts_from_xbrl(xml)

    assert_equal 2, facts.size
    assert_includes facts.keys, "a1101"
    assert_includes facts.keys, "a1102"
    assert_equal "42", facts["a1101"]
    assert_equal "100", facts["a1102"]
  end

  test "extract_context_from_xbrl returns context info" do
    xml = <<~XML
      <?xml version="1.0"?>
      <xbrl xmlns="http://www.xbrl.org/2003/instance">
        <context id="ctx_entity">
          <entity>
            <identifier scheme="http://amsf.mc/rci">RCI12345</identifier>
          </entity>
          <period>
            <instant>2025-12-31</instant>
          </period>
        </context>
      </xbrl>
    XML

    context = extract_context_from_xbrl(xml)

    assert_equal "RCI12345", context[:entity_id]
    assert_equal "2025-12-31", context[:period]
  end

  # === Phase 2: Baseline Tests ===

  test "old code generates valid XBRL structure" do
    # Skip if submission has no values (will fail legitimately)
    skip "No submission values to test" if @submission.submission_values.empty?

    xbrl = generate_xbrl_with_old_code(@submission)

    assert_valid_xbrl_structure(xbrl)
  end

  test "gem generates valid XBRL structure" do
    gem_submission = create_gem_submission(@submission)
    xbrl = AmsfSurvey.to_xbrl(gem_submission, pretty: true)

    assert_valid_xbrl_structure(xbrl)
  end

  # === Comparison Test (T007) - Will pass after refactoring ===

  test "gem XBRL contains all facts from old code" do
    skip "Comparison test - run after Phase 3 implementation" unless gem_xbrl_integration_complete?

    old_xbrl = generate_xbrl_with_old_code(@submission)
    old_facts = extract_facts_from_xbrl(old_xbrl)

    gem_submission = create_gem_submission(@submission)
    new_xbrl = AmsfSurvey.to_xbrl(gem_submission, pretty: true)
    new_facts = extract_facts_from_xbrl(new_xbrl)

    # All facts from old code should be in new code
    missing_facts = old_facts.keys - new_facts.keys
    assert_empty missing_facts, "Facts missing in gem output: #{missing_facts.join(', ')}"

    # Fact values should match
    old_facts.each do |field_id, old_value|
      new_value = new_facts[field_id]
      assert_equal old_value, new_value,
        "Value mismatch for #{field_id}: old=#{old_value.inspect}, new=#{new_value.inspect}"
    end
  end

  private

  # Populate submission with test values for comparison
  def populate_test_values(submission)
    # Use CalculationEngine to populate values, then add some manual ones
    CalculationEngine.new(submission).populate_submission_values!

    # Ensure we have some basic values for testing
    test_values = {
      "a1101" => "10",      # Total clients
      "tGATE" => "Oui"      # Gate field
    }

    test_values.each do |element_name, value|
      sv = submission.submission_values.find_or_initialize_by(element_name: element_name)
      sv.update!(value: value, source: "manual") unless sv.persisted? && sv.value.present?
    end
  end

  # Generate XBRL using the old ERB template approach
  def generate_xbrl_with_old_code(submission)
    SubmissionRenderer.new(submission).to_xbrl
  end

  # Create a gem submission from an AR submission
  def create_gem_submission(ar_submission)
    gem_submission = AmsfSurvey.build_submission(
      industry: :real_estate,
      year: ar_submission.year,
      entity_id: ar_submission.organization.rci_number,
      period: Date.new(ar_submission.year, 12, 31)
    )

    # Transfer values from AR submission to gem submission
    ar_submission.submission_values.each do |sv|
      begin
        gem_submission[sv.element_name.to_sym] = sv.value
      rescue AmsfSurvey::UnknownFieldError
        # Skip fields not in the gem questionnaire
        Rails.logger.debug "Skipping unknown field: #{sv.element_name}"
      end
    end

    gem_submission
  end

  # Normalize XBRL for comparison (removes whitespace differences)
  def normalize_xbrl(xml_string)
    doc = Nokogiri::XML(xml_string) { |config| config.noblanks }
    doc.to_xml(indent: 0, save_with: Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
        .gsub(/>\s+</, "><")
        .gsub(/\s+/, " ")
        .strip
  end

  # Extract fact elements from XBRL (field_id => value)
  def extract_facts_from_xbrl(xml_string)
    doc = Nokogiri::XML(xml_string)
    doc.remove_namespaces!

    facts = {}

    # Find all strix: prefixed elements (facts)
    doc.xpath("//*[starts-with(name(), 'strix:')]").each do |node|
      field_id = node.name.sub(/^strix:/, "")
      facts[field_id] = node.text.strip
    end

    # Also find elements in the strix namespace without prefix
    doc.xpath("//*[@contextRef]").each do |node|
      field_id = node.name
      next if field_id.start_with?("xbrl") || field_id.start_with?("context")

      facts[field_id] = node.text.strip
    end

    facts
  end

  # Extract context information from XBRL
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

  # Assert XBRL has valid structure
  def assert_valid_xbrl_structure(xbrl_string)
    doc = Nokogiri::XML(xbrl_string)

    # Check for XML errors
    assert doc.errors.empty?, "XBRL has XML errors: #{doc.errors.map(&:message).join(', ')}"

    doc.remove_namespaces!

    # Must have xbrl root
    assert doc.at_xpath("//xbrl") || doc.root&.name == "xbrl",
      "XBRL must have xbrl root element"

    # Must have at least one context
    assert doc.at_xpath("//context"),
      "XBRL must have at least one context element"

    # Context must have entity and period
    context = doc.at_xpath("//context")
    assert context.at_xpath(".//entity"),
      "Context must have entity element"
    assert context.at_xpath(".//period"),
      "Context must have period element"
  end

  # Check if gem XBRL integration is complete (Phase 3)
  def gem_xbrl_integration_complete?
    # This will be true after Phase 3 implementation
    # For now, check if SubmissionBuilder has gem_submission method
    SubmissionBuilder.instance_methods.include?(:gem_submission)
  end

  # === Phase 7: Multi-Year Tests (T042-T043) ===

  public

  test "questionnaire for 2025 loads with expected field count" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)

    assert_not_nil questionnaire, "2025 questionnaire should load"
    assert questionnaire.field_count > 0, "Questionnaire should have fields"
    assert questionnaire.section_count > 0, "Questionnaire should have sections"

    # AMSF real estate questionnaire typically has 600+ fields
    assert questionnaire.field_count >= 100,
           "Expected 100+ fields, got #{questionnaire.field_count}"
  end

  test "supported_years returns array including 2025" do
    years = AmsfSurvey.supported_years(:real_estate)

    assert years.is_a?(Array), "Should return an array"
    assert years.include?(2025), "Should support 2025"
  end

  test "unsupported year raises TaxonomyLoadError" do
    # Year 1999 is definitely not supported
    assert_raises(AmsfSurvey::TaxonomyLoadError) do
      AmsfSurvey.questionnaire(industry: :real_estate, year: 1999)
    end
  end

  test "SubmissionBuilder handles unsupported year gracefully" do
    # Use a year that's not supported (far future)
    builder = SubmissionBuilder.new(@organization, year: 2099)
    result = builder.build

    # Build should succeed (graceful degradation)
    assert result.success?, "Build should succeed for unsupported year"

    # gem_submission should be nil for unsupported years
    assert_nil builder.gem_submission, "gem_submission should be nil for unsupported year"
  end

  test "questionnaire field lookup works for 2025" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)

    # Look up a known field
    field = questionnaire.field(:aACTIVE)

    assert_not_nil field, "Should find aACTIVE field"
    assert_equal :aACTIVE, field.id
  end

  test "ElementManifest returns nil questionnaire for unsupported year" do
    # Create a submission for an unsupported year
    submission = Submission.find_or_create_by!(organization: @organization, year: 2099)
    manifest = Xbrl::ElementManifest.new(submission)

    assert_nil manifest.questionnaire, "Questionnaire should be nil for unsupported year"
    assert_equal [], manifest.all_fields, "all_fields should return empty array"
    assert_equal({}, manifest.fields_by_section, "fields_by_section should return empty hash")
  end
end
