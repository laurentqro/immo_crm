# frozen_string_literal: true

require "test_helper"
require "support/xbrl_test_helper"

# Base class for all XBRL compliance tests.
#
# Provides:
# - XbrlTestHelper module for XSD parsing and XBRL validation
# - Common setup with compliance_test_org organization
# - Helper method to generate XBRL from a submission
#
# All compliance test classes should inherit from this class:
#   class XbrlTaxonomyTest < XbrlComplianceTestCase
class XbrlComplianceTestCase < ActiveSupport::TestCase
  include XbrlTestHelper

  def setup
    @organization = organizations(:compliance_test_org)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # Generate XBRL for a submission with calculated values.
  #
  # @param submission [Submission] The submission to generate XBRL for
  # @return [String] Generated XBRL XML string
  def generate_xbrl_for(submission)
    CalculationEngine.new(submission).populate_submission_values!
    XbrlGenerator.new(submission).generate
  end

  # Create a submission for the current year with the compliance test organization.
  #
  # @param year [Integer] The reporting year (defaults to current year)
  # @return [Submission] A new submission ready for XBRL generation
  def create_compliance_submission(year: Date.current.year)
    Submission.create!(
      organization: @organization,
      year: year,
      status: "draft"
    )
  end

  # Assert element name exists in taxonomy with helpful error message.
  #
  # @param element_name [String] Element name to check
  def assert_valid_element_name(element_name)
    valid = XbrlTestHelper.valid_element_names.include?(element_name)
    suggestion = XbrlTestHelper.suggest_element_name(element_name) unless valid

    assert valid,
      "Element '#{element_name}' not found in taxonomy. " \
      "Did you mean: #{suggestion}?"
  end

  # Assert all generated elements exist in taxonomy.
  #
  # @param xbrl_doc [Nokogiri::XML::Document] Parsed XBRL document
  def assert_all_elements_valid(xbrl_doc)
    invalid_elements = []

    extract_element_names(xbrl_doc).each do |name|
      unless XbrlTestHelper.valid_element_names.include?(name)
        suggestion = XbrlTestHelper.suggest_element_name(name)
        invalid_elements << "#{name} (did you mean: #{suggestion}?)"
      end
    end

    assert invalid_elements.empty?,
      "Found #{invalid_elements.size} invalid element(s):\n  #{invalid_elements.join("\n  ")}"
  end
end
