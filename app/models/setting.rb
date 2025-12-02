# frozen_string_literal: true

# Setting stores organization-wide configuration as key-value pairs.
# Settings are grouped by category and can have different value types.
# Many settings map to XBRL elements for AMSF compliance reporting.
#
# == Schema
#   organization_id: integer (FK)
#   key:            string (unique per org)
#   value:          string (stored as text, cast via typed_value)
#   value_type:     enum - boolean|integer|decimal|string|date|enum
#   category:       enum - entity_info|kyc_procedures|compliance_policies|training
#   xbrl_element:   string (optional AMSF element code like "a4101")
#
# == Usage
#   setting = organization.settings.find_by(key: "edd_for_peps")
#   setting.value      # => "true" (stored string)
#   setting.typed_value # => true  (cast to boolean)
#
class Setting < ApplicationRecord
  # Valid categories matching AMSF compliance sections
  CATEGORIES = %w[entity_info kyc_procedures compliance_policies training].freeze

  # Supported value types with corresponding cast behavior
  VALUE_TYPES = %w[boolean integer decimal string date enum].freeze

  # Schema for known settings with their types, categories, and XBRL mappings.
  # This is the single source of truth for valid setting keys.
  # Used by SettingsController for strong parameters and SettingsSeeder for defaults.
  SCHEMA = {
    # Entity Info - Basic organization information (XBRL section a01xx)
    "entity_name" => {value_type: "string", category: "entity_info", xbrl: "a0101"},
    "total_employees" => {value_type: "integer", category: "entity_info", xbrl: "a0102"},
    "compliance_officers" => {value_type: "integer", category: "entity_info", xbrl: "a0103"},
    "annual_revenue" => {value_type: "decimal", category: "entity_info", xbrl: "a0104"},
    # KYC Procedures - Due diligence settings (XBRL section a41xx)
    "edd_for_peps" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4101"},
    "edd_for_high_risk_countries" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4102"},
    "edd_for_complex_structures" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4103"},
    "sdd_applied" => {value_type: "boolean", category: "kyc_procedures", xbrl: "a4104"},
    # Compliance Policies - Policy documentation (XBRL section a51xx)
    "written_aml_policy" => {value_type: "boolean", category: "compliance_policies", xbrl: "a5101"},
    "policy_last_updated" => {value_type: "date", category: "compliance_policies", xbrl: "a5102"},
    "risk_assessment_performed" => {value_type: "boolean", category: "compliance_policies", xbrl: "a5103"},
    "internal_controls" => {value_type: "boolean", category: "compliance_policies", xbrl: "a5104"},
    # Training - Staff training settings (XBRL section a61xx)
    "training_frequency" => {value_type: "enum", category: "training", xbrl: "a6101"},
    "last_training_date" => {value_type: "date", category: "training", xbrl: "a6102"},
    "training_covers_aml" => {value_type: "boolean", category: "training", xbrl: "a6103"}
  }.freeze

  belongs_to :organization

  validates :key, presence: true, uniqueness: {scope: :organization_id}
  validates :value_type, presence: true, inclusion: {in: VALUE_TYPES}
  validates :category, presence: true, inclusion: {in: CATEGORIES}
  validates :xbrl_element, format: {with: /\A[a-z]\d{4}\z/, allow_blank: true}
  validate :value_matches_type

  # === Scopes ===

  scope :by_category, ->(category) { where(category: category) }
  scope :for_organization, ->(org) { where(organization: org) }

  # === Type Casting ===

  # Returns the value cast to its appropriate Ruby type.
  # All values are stored as strings in the database.
  # Returns nil for empty values or invalid formats (e.g., invalid dates).
  #
  # @return [Object, nil] The typed value or nil if empty/invalid
  def typed_value
    return nil if value.nil? || value.empty?

    case value_type
    when "boolean"
      # Accept common boolean representations from forms
      value.in?(%w[true 1])
    when "integer"
      value.to_i
    when "decimal"
      BigDecimal(value)
    when "date"
      Date.parse(value)
    when "enum", "string"
      value
    else
      value
    end
  rescue ArgumentError, Date::Error
    # Return nil for invalid date formats instead of raising
    nil
  end

  # === Type Predicates ===

  def boolean?
    value_type == "boolean"
  end

  def integer?
    value_type == "integer"
  end

  def decimal?
    value_type == "decimal"
  end

  def date?
    value_type == "date"
  end

  def enum?
    value_type == "enum"
  end

  private

  # Validates that the value can be cast to the declared value_type.
  # Prevents saving invalid data that would silently return nil from typed_value.
  def value_matches_type
    return if value.blank?

    case value_type
    when "date"
      Date.parse(value)
    when "decimal"
      BigDecimal(value)
    when "integer"
      raise ArgumentError unless value.match?(/\A-?\d+\z/)
    end
  rescue ArgumentError, Date::Error
    errors.add(:value, "is not a valid #{value_type}")
  end
end
