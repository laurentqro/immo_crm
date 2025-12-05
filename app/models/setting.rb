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
  CATEGORIES = %w[entity_info kyc_procedures compliance_policies training controls].freeze

  # Supported value types with corresponding cast behavior
  VALUE_TYPES = %w[boolean integer decimal string date enum].freeze

  # Schema for known settings with their types, categories, and XBRL mappings.
  # This is the single source of truth for valid setting keys.
  # Used by SettingsController for strong parameters and SettingsSeeder for defaults.
  #
  # Controls (aC*) are Tab 4 policy questions from AMSF taxonomy - all Oui/Non.
  # Keys use format: ctrl_<element> for easy identification and future renaming.
  #
  # Migration Note: When exposing controls in the UI, consider:
  # - Adding human-readable labels from taxonomy label file
  # - Grouping by AMSF sections (1.1 Risk Policy, 1.2 KYC, etc.)
  # - Adding help text from taxonomy definition file
  SCHEMA = {
    # === Entity Info ===
    # Organization-level data required for AMSF survey
    "entity_name" => {value_type: "string", category: "entity_info", xbrl: nil},
    "entity_legal_form" => {value_type: "enum", category: "entity_info", xbrl: nil},
    "amsf_registration_number" => {value_type: "string", category: "entity_info", xbrl: nil},
    "total_employees" => {value_type: "integer", category: "entity_info", xbrl: nil},
    "compliance_officers" => {value_type: "integer", category: "entity_info", xbrl: nil},
    "annual_revenue" => {value_type: "decimal", category: "entity_info", xbrl: nil},

    # === Activity Flags ===
    # aACTIVE* elements indicate which business lines the agency operates
    "activity_sales" => {value_type: "boolean", category: "entity_info", xbrl: "aACTIVE"},
    "activity_rentals" => {value_type: "boolean", category: "entity_info", xbrl: "aACTIVERENTALS"},
    "activity_property_management" => {value_type: "boolean", category: "entity_info", xbrl: "aACTIVEPS"},

    # === Staffing ===
    # Staff counts for Tab 1 entity profile
    "staff_total" => {value_type: "integer", category: "entity_info", xbrl: "a11006"},
    "staff_compliance" => {value_type: "integer", category: "entity_info", xbrl: "aC11502"},
    "uses_external_compliance" => {value_type: "boolean", category: "entity_info", xbrl: "aC11508"},

    # === Tab 4: Controls (105 aC* policy questions) ===
    # All are Oui/Non (boolean) questions about organizational policies.
    # Format: ctrl_<element_code> => maps to XBRL element
    "ctrl_aC1101Z" => {value_type: "boolean", category: "controls", xbrl: "aC1101Z"},
    "ctrl_aC1102" => {value_type: "boolean", category: "controls", xbrl: "aC1102"},
    "ctrl_aC1102A" => {value_type: "boolean", category: "controls", xbrl: "aC1102A"},
    "ctrl_aC1106" => {value_type: "boolean", category: "controls", xbrl: "aC1106"},
    "ctrl_aC11101" => {value_type: "boolean", category: "controls", xbrl: "aC11101"},
    "ctrl_aC11102" => {value_type: "boolean", category: "controls", xbrl: "aC11102"},
    "ctrl_aC11103" => {value_type: "boolean", category: "controls", xbrl: "aC11103"},
    "ctrl_aC11104" => {value_type: "boolean", category: "controls", xbrl: "aC11104"},
    "ctrl_aC11105" => {value_type: "boolean", category: "controls", xbrl: "aC11105"},
    "ctrl_aC11201" => {value_type: "boolean", category: "controls", xbrl: "aC11201"},
    "ctrl_aC1125A" => {value_type: "boolean", category: "controls", xbrl: "aC1125A"},
    "ctrl_aC11301" => {value_type: "boolean", category: "controls", xbrl: "aC11301"},
    "ctrl_aC11302" => {value_type: "boolean", category: "controls", xbrl: "aC11302"},
    "ctrl_aC11303" => {value_type: "boolean", category: "controls", xbrl: "aC11303"},
    "ctrl_aC11304" => {value_type: "boolean", category: "controls", xbrl: "aC11304"},
    "ctrl_aC11305" => {value_type: "boolean", category: "controls", xbrl: "aC11305"},
    "ctrl_aC11306" => {value_type: "boolean", category: "controls", xbrl: "aC11306"},
    "ctrl_aC11307" => {value_type: "boolean", category: "controls", xbrl: "aC11307"},
    "ctrl_aC114" => {value_type: "boolean", category: "controls", xbrl: "aC114"},
    "ctrl_aC11401" => {value_type: "boolean", category: "controls", xbrl: "aC11401"},
    "ctrl_aC11402" => {value_type: "boolean", category: "controls", xbrl: "aC11402"},
    "ctrl_aC11403" => {value_type: "boolean", category: "controls", xbrl: "aC11403"},
    "ctrl_aC11501B" => {value_type: "boolean", category: "controls", xbrl: "aC11501B"},
    "ctrl_aC11502" => {value_type: "boolean", category: "controls", xbrl: "aC11502"},
    "ctrl_aC11504" => {value_type: "boolean", category: "controls", xbrl: "aC11504"},
    "ctrl_aC11508" => {value_type: "boolean", category: "controls", xbrl: "aC11508"},
    "ctrl_aC11601" => {value_type: "boolean", category: "controls", xbrl: "aC11601"},
    "ctrl_aC116A" => {value_type: "boolean", category: "controls", xbrl: "aC116A"},
    "ctrl_aC1201" => {value_type: "boolean", category: "controls", xbrl: "aC1201"},
    "ctrl_aC1202" => {value_type: "boolean", category: "controls", xbrl: "aC1202"},
    "ctrl_aC1203" => {value_type: "boolean", category: "controls", xbrl: "aC1203"},
    "ctrl_aC1204" => {value_type: "boolean", category: "controls", xbrl: "aC1204"},
    "ctrl_aC1205" => {value_type: "boolean", category: "controls", xbrl: "aC1205"},
    "ctrl_aC1206" => {value_type: "boolean", category: "controls", xbrl: "aC1206"},
    "ctrl_aC1207" => {value_type: "boolean", category: "controls", xbrl: "aC1207"},
    "ctrl_aC1208" => {value_type: "boolean", category: "controls", xbrl: "aC1208"},
    "ctrl_aC1209" => {value_type: "boolean", category: "controls", xbrl: "aC1209"},
    "ctrl_aC1209B" => {value_type: "boolean", category: "controls", xbrl: "aC1209B"},
    "ctrl_aC1209C" => {value_type: "boolean", category: "controls", xbrl: "aC1209C"},
    "ctrl_aC12236" => {value_type: "boolean", category: "controls", xbrl: "aC12236"},
    "ctrl_aC12237" => {value_type: "boolean", category: "controls", xbrl: "aC12237"},
    "ctrl_aC12333" => {value_type: "boolean", category: "controls", xbrl: "aC12333"},
    "ctrl_aC1301" => {value_type: "boolean", category: "controls", xbrl: "aC1301"},
    "ctrl_aC1302" => {value_type: "boolean", category: "controls", xbrl: "aC1302"},
    "ctrl_aC1303" => {value_type: "boolean", category: "controls", xbrl: "aC1303"},
    "ctrl_aC1304" => {value_type: "boolean", category: "controls", xbrl: "aC1304"},
    "ctrl_aC1401" => {value_type: "boolean", category: "controls", xbrl: "aC1401"},
    "ctrl_aC1402" => {value_type: "boolean", category: "controls", xbrl: "aC1402"},
    "ctrl_aC1403" => {value_type: "boolean", category: "controls", xbrl: "aC1403"},
    "ctrl_aC1501" => {value_type: "boolean", category: "controls", xbrl: "aC1501"},
    "ctrl_aC1503B" => {value_type: "boolean", category: "controls", xbrl: "aC1503B"},
    "ctrl_aC1506" => {value_type: "boolean", category: "controls", xbrl: "aC1506"},
    "ctrl_aC1518A" => {value_type: "boolean", category: "controls", xbrl: "aC1518A"},
    "ctrl_aC1601" => {value_type: "boolean", category: "controls", xbrl: "aC1601"},
    "ctrl_aC1602" => {value_type: "boolean", category: "controls", xbrl: "aC1602"},
    "ctrl_aC1608" => {value_type: "boolean", category: "controls", xbrl: "aC1608"},
    "ctrl_aC1609" => {value_type: "boolean", category: "controls", xbrl: "aC1609"},
    "ctrl_aC1610" => {value_type: "boolean", category: "controls", xbrl: "aC1610"},
    "ctrl_aC1611" => {value_type: "boolean", category: "controls", xbrl: "aC1611"},
    "ctrl_aC1612" => {value_type: "boolean", category: "controls", xbrl: "aC1612"},
    "ctrl_aC1612A" => {value_type: "boolean", category: "controls", xbrl: "aC1612A"},
    "ctrl_aC1614" => {value_type: "boolean", category: "controls", xbrl: "aC1614"},
    "ctrl_aC1615" => {value_type: "boolean", category: "controls", xbrl: "aC1615"},
    "ctrl_aC1616A" => {value_type: "boolean", category: "controls", xbrl: "aC1616A"},
    "ctrl_aC1616B" => {value_type: "boolean", category: "controls", xbrl: "aC1616B"},
    "ctrl_aC1616C" => {value_type: "boolean", category: "controls", xbrl: "aC1616C"},
    "ctrl_aC1617" => {value_type: "boolean", category: "controls", xbrl: "aC1617"},
    "ctrl_aC1618" => {value_type: "boolean", category: "controls", xbrl: "aC1618"},
    "ctrl_aC1619" => {value_type: "boolean", category: "controls", xbrl: "aC1619"},
    "ctrl_aC1620" => {value_type: "boolean", category: "controls", xbrl: "aC1620"},
    "ctrl_aC1621" => {value_type: "boolean", category: "controls", xbrl: "aC1621"},
    "ctrl_aC1622A" => {value_type: "boolean", category: "controls", xbrl: "aC1622A"},
    "ctrl_aC1622B" => {value_type: "boolean", category: "controls", xbrl: "aC1622B"},
    "ctrl_aC1622F" => {value_type: "boolean", category: "controls", xbrl: "aC1622F"},
    "ctrl_aC1625" => {value_type: "boolean", category: "controls", xbrl: "aC1625"},
    "ctrl_aC1626" => {value_type: "boolean", category: "controls", xbrl: "aC1626"},
    "ctrl_aC1627" => {value_type: "boolean", category: "controls", xbrl: "aC1627"},
    "ctrl_aC1629" => {value_type: "boolean", category: "controls", xbrl: "aC1629"},
    "ctrl_aC1630" => {value_type: "boolean", category: "controls", xbrl: "aC1630"},
    "ctrl_aC1631" => {value_type: "boolean", category: "controls", xbrl: "aC1631"},
    "ctrl_aC1633" => {value_type: "boolean", category: "controls", xbrl: "aC1633"},
    "ctrl_aC1634" => {value_type: "boolean", category: "controls", xbrl: "aC1634"},
    "ctrl_aC1635" => {value_type: "boolean", category: "controls", xbrl: "aC1635"},
    "ctrl_aC1635A" => {value_type: "boolean", category: "controls", xbrl: "aC1635A"},
    "ctrl_aC1636" => {value_type: "boolean", category: "controls", xbrl: "aC1636"},
    "ctrl_aC1637" => {value_type: "boolean", category: "controls", xbrl: "aC1637"},
    "ctrl_aC1638A" => {value_type: "boolean", category: "controls", xbrl: "aC1638A"},
    "ctrl_aC1639A" => {value_type: "boolean", category: "controls", xbrl: "aC1639A"},
    "ctrl_aC1640A" => {value_type: "boolean", category: "controls", xbrl: "aC1640A"},
    "ctrl_aC1641A" => {value_type: "boolean", category: "controls", xbrl: "aC1641A"},
    "ctrl_aC1642A" => {value_type: "boolean", category: "controls", xbrl: "aC1642A"},
    "ctrl_aC168" => {value_type: "boolean", category: "controls", xbrl: "aC168"},
    "ctrl_aC1701" => {value_type: "boolean", category: "controls", xbrl: "aC1701"},
    "ctrl_aC1702" => {value_type: "boolean", category: "controls", xbrl: "aC1702"},
    "ctrl_aC1703" => {value_type: "boolean", category: "controls", xbrl: "aC1703"},
    "ctrl_aC171" => {value_type: "boolean", category: "controls", xbrl: "aC171"},
    "ctrl_aC1801" => {value_type: "boolean", category: "controls", xbrl: "aC1801"},
    "ctrl_aC1802" => {value_type: "boolean", category: "controls", xbrl: "aC1802"},
    "ctrl_aC1806" => {value_type: "boolean", category: "controls", xbrl: "aC1806"},
    "ctrl_aC1807" => {value_type: "boolean", category: "controls", xbrl: "aC1807"},
    "ctrl_aC1811" => {value_type: "boolean", category: "controls", xbrl: "aC1811"},
    "ctrl_aC1812" => {value_type: "boolean", category: "controls", xbrl: "aC1812"},
    "ctrl_aC1813" => {value_type: "boolean", category: "controls", xbrl: "aC1813"},
    "ctrl_aC1814W" => {value_type: "boolean", category: "controls", xbrl: "aC1814W"},
    "ctrl_aC1904" => {value_type: "boolean", category: "controls", xbrl: "aC1904"}
  }.freeze

  belongs_to :organization

  validates :key, presence: true, uniqueness: {scope: :organization_id}
  validates :value_type, presence: true, inclusion: {in: VALUE_TYPES}
  validates :category, presence: true, inclusion: {in: CATEGORIES}
  # XBRL element codes: aC1101Z, a2102B, a11502B, aACTIVE, aACTIVEPS, etc.
  # Pattern: either aACTIVE variants OR a + optional letter (C for controls) + 3-5 digits + 0-2 trailing letters
  validates :xbrl_element, format: {with: /\Aa(ACTIVE[A-Z]*|[A-Z]?\d{3,5}[A-Z]{0,2})\z/, allow_blank: true}
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
