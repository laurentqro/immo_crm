# frozen_string_literal: true

# Seeds default settings for a new organization.
# Creates all standard AML/CFT compliance settings with sensible defaults.
#
# Usage:
#   SettingsSeeder.new(organization).seed!
#
class SettingsSeeder
  # Default settings schema matching XBRL elements for AMSF compliance
  DEFAULT_SETTINGS = [
    # Entity Information
    {key: "entity_name", value: "", value_type: "string", category: "entity_info", xbrl_element: "a0101"},
    {key: "total_employees", value: "0", value_type: "integer", category: "entity_info", xbrl_element: "a0102"},
    {key: "compliance_officers", value: "0", value_type: "integer", category: "entity_info", xbrl_element: "a0103"},
    {key: "annual_revenue", value: "0.00", value_type: "decimal", category: "entity_info", xbrl_element: "a0104"},

    # KYC Procedures - Default to enabled for conservative compliance
    {key: "edd_for_peps", value: "true", value_type: "boolean", category: "kyc_procedures", xbrl_element: "a4101"},
    {key: "edd_for_high_risk_countries", value: "true", value_type: "boolean", category: "kyc_procedures", xbrl_element: "a4102"},
    {key: "edd_for_complex_structures", value: "true", value_type: "boolean", category: "kyc_procedures", xbrl_element: "a4103"},
    {key: "sdd_applied", value: "false", value_type: "boolean", category: "kyc_procedures", xbrl_element: "a4104"},

    # Compliance Policies
    {key: "written_aml_policy", value: "false", value_type: "boolean", category: "compliance_policies", xbrl_element: "a5101"},
    {key: "policy_last_updated", value: "", value_type: "date", category: "compliance_policies", xbrl_element: "a5102"},
    {key: "risk_assessment_performed", value: "false", value_type: "boolean", category: "compliance_policies", xbrl_element: "a5103"},
    {key: "internal_controls", value: "false", value_type: "boolean", category: "compliance_policies", xbrl_element: "a5104"},

    # Training
    {key: "training_frequency", value: "annual", value_type: "enum", category: "training", xbrl_element: "a6101"},
    {key: "last_training_date", value: "", value_type: "date", category: "training", xbrl_element: "a6102"},
    {key: "training_covers_aml", value: "false", value_type: "boolean", category: "training", xbrl_element: "a6103"}
  ].freeze

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  # Seeds all default settings for the organization.
  # Skips settings that already exist.
  #
  # @return [Array<Setting>] The created settings
  def seed!
    created_settings = []

    DEFAULT_SETTINGS.each do |attrs|
      next if organization.settings.exists?(key: attrs[:key])

      setting = organization.settings.create!(attrs)
      created_settings << setting
    end

    created_settings
  end

  # Checks if all default settings exist for the organization.
  #
  # @return [Boolean] true if all settings exist
  def complete?
    existing_keys = organization.settings.pluck(:key)
    required_keys = DEFAULT_SETTINGS.map { |s| s[:key] }
    (required_keys - existing_keys).empty?
  end

  # Returns missing setting keys for the organization.
  #
  # @return [Array<String>] List of missing setting keys
  def missing_keys
    existing_keys = organization.settings.pluck(:key)
    required_keys = DEFAULT_SETTINGS.map { |s| s[:key] }
    required_keys - existing_keys
  end
end
