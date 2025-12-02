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

  belongs_to :organization

  validates :key, presence: true, uniqueness: {scope: :organization_id}
  validates :value_type, presence: true, inclusion: {in: VALUE_TYPES}
  validates :category, presence: true, inclusion: {in: CATEGORIES}

  # === Scopes ===

  scope :by_category, ->(category) { where(category: category) }
  scope :for_organization, ->(org) { where(organization: org) }

  # === Type Casting ===

  # Returns the value cast to its appropriate Ruby type.
  # All values are stored as strings in the database.
  #
  # @return [Object, nil] The typed value or nil if empty
  def typed_value
    return nil if value.nil? || value.empty?

    case value_type
    when "boolean"
      value.in?(%w[true 1 yes])
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
end
