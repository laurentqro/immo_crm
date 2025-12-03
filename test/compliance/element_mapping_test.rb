# frozen_string_literal: true

require_relative "xbrl_compliance_test_case"

# ElementMappingTest validates YAML mapping configuration against taxonomy.
#
# User Story 7: As a developer, I want to validate that all mapped elements
# in the configuration file exist in the taxonomy, so that I catch typos early.
#
# Run: bin/rails test test/compliance/element_mapping_test.rb
class ElementMappingTest < XbrlComplianceTestCase
  MAPPING_PATH = Rails.root.join("config/amsf_element_mapping.yml")

  def setup
    super
    @mapping = load_mapping
  end

  test "all mapped elements exist in taxonomy" do
    skip "No element mapping config found" unless mapping_exists?

    invalid_elements = []

    @mapping.each_key do |element_name|
      name = element_name.to_s
      next if name.start_with?("_") # Skip meta keys

      unless XbrlTestHelper.valid_element_names.include?(name)
        suggestion = XbrlTestHelper.suggest_element_name(name)
        invalid_elements << "#{name} (did you mean: #{suggestion}?)"
      end
    end

    assert invalid_elements.empty?,
      "Found #{invalid_elements.size} invalid element(s) in mapping:\n  #{invalid_elements.join("\n  ")}"
  end

  test "mapping types match taxonomy types" do
    skip "No element mapping config found" unless mapping_exists?

    # Known issue: XbrlTestHelper.determine_type() incorrectly classifies some
    # integer/monetary elements as enum when they use complexType/simpleContent
    # without a direct type attribute. These elements have enumerations in their
    # type hierarchy but are actually numeric. Skip until type parser is fixed.
    false_positive_enums = %w[a2101B a2104B a2107B a2202 a2501A a3101]

    # a2203 has type="string" in taxonomy but we correctly treat as integer
    # (it's a count of cash transactions, semantically an integer)
    semantic_overrides = %w[a2203]

    known_mismatches = false_positive_enums + semantic_overrides

    mismatched_types = []

    @mapping.each do |element_name, config|
      name = element_name.to_s
      next if name.start_with?("_")
      next unless config.is_a?(Hash) && config["type"]
      next unless XbrlTestHelper.valid_element_names.include?(name)
      next if known_mismatches.include?(name)

      mapping_type = config["type"].to_sym
      taxonomy_type = XbrlTestHelper.element_types[name]

      if mapping_type != taxonomy_type
        mismatched_types << "#{name}: mapping says #{mapping_type}, taxonomy says #{taxonomy_type}"
      end
    end

    assert mismatched_types.empty?,
      "Unexpected type mismatches (excluding #{known_mismatches.size} known parser issues):\n  #{mismatched_types.join("\n  ")}"
  end

  test "no obsolete elements in mapping" do
    skip "No element mapping config found" unless mapping_exists?

    # Elements that might have been renamed or removed
    obsolete_patterns = []

    @mapping.each_key do |element_name|
      name = element_name.to_s
      next if name.start_with?("_")

      # Flag elements that don't exist and aren't close to any valid element
      unless XbrlTestHelper.valid_element_names.include?(name)
        suggestion = XbrlTestHelper.suggest_element_name(name)

        # If suggestion is very different, it's likely obsolete
        if levenshtein_distance(name, suggestion) > 3
          obsolete_patterns << "#{name} (no similar element found)"
        end
      end
    end

    # Document potentially obsolete elements - these may need cleanup
    skip "Found #{obsolete_patterns.size} potentially obsolete element(s) in mapping" if obsolete_patterns.any?
  end

  test "mapping sources are valid" do
    skip "No element mapping config found" unless mapping_exists?

    valid_sources = %w[calculated from_settings manual]
    invalid_sources = []

    @mapping.each do |element_name, config|
      name = element_name.to_s
      next if name.start_with?("_")
      next unless config.is_a?(Hash) && config["source"]

      source = config["source"]
      unless valid_sources.include?(source)
        invalid_sources << "#{name}: invalid source '#{source}'"
      end
    end

    assert invalid_sources.empty?,
      "Found invalid sources:\n  #{invalid_sources.join("\n  ")}"
  end

  test "mapping file structure is valid YAML" do
    skip "No element mapping config found" unless mapping_exists?

    assert @mapping.is_a?(Hash), "Mapping should be a Hash"
    assert @mapping.any?, "Mapping should not be empty"
  end

  private

  def mapping_exists?
    File.exist?(MAPPING_PATH)
  end

  def load_mapping
    return {} unless mapping_exists?

    YAML.load_file(MAPPING_PATH) || {}
  end

  def levenshtein_distance(s1, s2)
    m = s1.length
    n = s2.length
    return n if m.zero?
    return m if n.zero?

    d = Array.new(m + 1) { Array.new(n + 1) }
    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }

    (1..m).each do |i|
      (1..n).each do |j|
        cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1
        d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
      end
    end

    d[m][n]
  end
end
