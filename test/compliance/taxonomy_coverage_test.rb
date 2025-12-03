# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# TaxonomyCoverageTest tracks how much of the AMSF taxonomy is covered
# by the current element mapping configuration.
#
# User Story 2: As a compliance officer, I want to track what percentage
# of the AMSF survey is covered by our system, so that I can prioritize
# which elements to implement next.
#
# Run: bin/rails test test/compliance/taxonomy_coverage_test.rb
class TaxonomyCoverageTest < XbrlComplianceTestCase
  MAPPING_PATH = Rails.root.join("config/amsf_element_mapping.yml")

  def setup
    super
    @mapping = load_element_mapping
  end

  test "reports total taxonomy element count" do
    assert_equal 323, XbrlTestHelper.taxonomy_elements.count,
      "Taxonomy should have exactly 323 non-abstract elements"
  end

  test "reports mapped element count" do
    skip "No element mapping config found" unless mapping_exists?

    valid_count = valid_mapped_elements.count
    total_mapped = all_mapped_elements.count
    invalid_count = total_mapped - valid_count

    puts "\n=== Mapping Statistics ==="
    puts "  Total entries in mapping: #{total_mapped}"
    puts "  Valid (exist in taxonomy): #{valid_count}"
    puts "  Invalid (wrong names): #{invalid_count}"

    # We expect SOME entries in the mapping (even if names are wrong)
    assert total_mapped.positive?, "Mapping should have at least some elements"
  end

  test "calculates coverage percentage" do
    skip "No element mapping config found" unless mapping_exists?

    total = 323
    mapped = valid_mapped_elements.count
    coverage = (mapped.to_f / total * 100).round(1)

    puts "\n=== Coverage: #{coverage}% (#{mapped}/#{total}) ==="

    # Assert we have some coverage (even if low)
    assert coverage >= 0, "Coverage should be non-negative"
    assert coverage <= 100, "Coverage should not exceed 100%"
  end

  test "lists unmapped elements by section" do
    skip "No element mapping config found" unless mapping_exists?

    unmapped = unmapped_elements_by_section
    report = generate_coverage_report(unmapped)

    puts "\n#{report}"

    # Verify report structure
    assert_includes report, "Tab 1"
    assert_includes report, "Tab 2"
    assert_includes report, "Tab 3"
    assert_includes report, "Controls"
  end

  test "outputs coverage report helper method" do
    skip "No element mapping config found" unless mapping_exists?

    report = full_coverage_report
    assert report.is_a?(Hash), "Report should be a Hash"
    assert_includes report.keys, :total_taxonomy_elements
    assert_includes report.keys, :mapped_elements
    assert_includes report.keys, :coverage_percentage
    assert_includes report.keys, :sections
  end

  private

  def mapping_exists?
    File.exist?(MAPPING_PATH)
  end

  def load_element_mapping
    return {} unless mapping_exists?

    YAML.load_file(MAPPING_PATH) || {}
  end

  def valid_mapped_elements
    @mapping.keys.map(&:to_s).select do |element_name|
      !element_name.start_with?("_") && # Skip meta keys
        XbrlTestHelper.valid_element_names.include?(element_name)
    end
  end

  def all_mapped_elements
    @mapping.keys.map(&:to_s).reject { |k| k.start_with?("_") }
  end

  def unmapped_elements_by_section
    mapped = valid_mapped_elements.to_set
    unmapped = XbrlTestHelper.valid_element_names - mapped

    {
      "Tab 1: Customer Risk" => unmapped.select { |e| e.match?(/^a1[12345]/) },
      "Tab 2: Products/Services" => unmapped.select { |e| e.match?(/^a2[125]/) },
      "Tab 3: Distribution" => unmapped.select { |e| e.match?(/^a3[123457]/) },
      "Tab 4: Controls" => unmapped.select { |e| e.match?(/^aC1/) },
      "Other Sections" => unmapped.select { |e| e.match?(/^(aAC|aB|aG|aIN|aIR|aML|aS)/) }
    }
  end

  def section_totals
    all_elements = XbrlTestHelper.valid_element_names

    {
      "Tab 1: Customer Risk" => all_elements.count { |e| e.match?(/^a1[12345]/) },
      "Tab 2: Products/Services" => all_elements.count { |e| e.match?(/^a2[125]/) },
      "Tab 3: Distribution" => all_elements.count { |e| e.match?(/^a3[123457]/) },
      "Tab 4: Controls" => all_elements.count { |e| e.match?(/^aC1/) },
      "Other Sections" => all_elements.count { |e| e.match?(/^(aAC|aB|aG|aIN|aIR|aML|aS)/) }
    }
  end

  def generate_coverage_report(unmapped_by_section)
    lines = ["=== XBRL Taxonomy Coverage Report ==="]
    lines << "Total taxonomy elements: 323"
    lines << "Mapped elements: #{valid_mapped_elements.count}"
    lines << "Coverage: #{(valid_mapped_elements.count.to_f / 323 * 100).round(1)}%"
    lines << ""
    lines << "By Section:"

    totals = section_totals

    unmapped_by_section.each do |section, elements|
      total = totals[section] || 0
      mapped = total - elements.size
      percentage = (total > 0) ? (mapped.to_f / total * 100).round(1) : 0
      lines << "  #{section}: #{mapped} / #{total} (#{percentage}%)"
    end

    lines.join("\n")
  end

  def full_coverage_report
    mapped = valid_mapped_elements.count
    unmapped = unmapped_elements_by_section
    totals = section_totals

    sections = {}
    unmapped.each do |section_name, elements|
      total = totals[section_name] || 0
      sections[section_name] = {
        total: total,
        mapped: total - elements.size,
        unmapped: elements.to_a
      }
    end

    {
      total_taxonomy_elements: 323,
      mapped_elements: mapped,
      coverage_percentage: (mapped.to_f / 323 * 100).round(1),
      unmapped_elements: (XbrlTestHelper.valid_element_names - valid_mapped_elements.to_set).to_a,
      sections: sections
    }
  end
end
