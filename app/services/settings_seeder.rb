# frozen_string_literal: true

# Seeds default settings for a new organization.
# Creates all standard AML/CFT compliance settings with sensible defaults.
# Uses Setting::SCHEMA as the single source of truth for valid settings.
#
# Usage:
#   SettingsSeeder.new(organization).seed!
#
class SettingsSeeder
  # Default values for each setting (schema comes from Setting::SCHEMA)
  DEFAULT_VALUES = {
    # Entity Information - empty/zero defaults
    "entity_name" => "",
    "total_employees" => "0",
    "compliance_officers" => "0",
    "annual_revenue" => "0.00",
    # KYC Procedures - conservative defaults (EDD enabled, SDD disabled)
    "edd_for_peps" => "true",
    "edd_for_high_risk_countries" => "true",
    "edd_for_complex_structures" => "true",
    "sdd_applied" => "false",
    # Compliance Policies - all false until configured
    "written_aml_policy" => "false",
    "policy_last_updated" => "",
    "risk_assessment_performed" => "false",
    "internal_controls" => "false",
    # Training - annual default
    "training_frequency" => "annual",
    "last_training_date" => "",
    "training_covers_aml" => "false"
  }.freeze

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  # Seeds all default settings for the organization.
  # Skips settings that already exist.
  # Logs errors but continues with remaining settings.
  #
  # @return [Array<Setting>] The created settings
  def seed!
    created_settings = []
    existing_keys = organization.settings.pluck(:key).to_set

    Setting::SCHEMA.each do |key, schema|
      next if existing_keys.include?(key)

      setting = organization.settings.create!(
        key: key,
        value: DEFAULT_VALUES[key] || "",
        value_type: schema[:value_type],
        category: schema[:category],
        xbrl_element: schema[:xbrl]
      )
      created_settings << setting
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("SettingsSeeder: Failed to create setting '#{key}': #{e.message}")
    end

    created_settings
  end

  # Checks if all default settings exist for the organization.
  #
  # @return [Boolean] true if all settings exist
  def complete?
    missing_keys.empty?
  end

  # Returns missing setting keys for the organization.
  #
  # @return [Array<String>] List of missing setting keys
  def missing_keys
    existing_keys = organization.settings.pluck(:key)
    Setting::SCHEMA.keys - existing_keys
  end
end
