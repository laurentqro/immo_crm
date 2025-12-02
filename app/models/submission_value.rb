# frozen_string_literal: true

# SubmissionValue model for storing individual XBRL element values.
# Each value is a snapshot captured during the submission process.
#
# Sources:
# - calculated: Derived from CRM data (client counts, transaction totals)
# - from_settings: Copied from organization settings (policies, entity info)
# - manual: Fresh questions answered annually
#
class SubmissionValue < ApplicationRecord
  include AmsfConstants

  # === Associations ===
  belongs_to :submission

  # === Validations ===
  validates :element_name, presence: true
  validates :element_name, uniqueness: { scope: :submission_id }
  validates :source, presence: true, inclusion: { in: SUBMISSION_VALUE_SOURCES }

  # === Scopes ===
  scope :calculated, -> { where(source: "calculated") }
  scope :from_settings, -> { where(source: "from_settings") }
  scope :manual, -> { where(source: "manual") }
  scope :overridden_values, -> { where(overridden: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :for_element, ->(name) { where(element_name: name) }

  # === Instance Methods ===

  def calculated?
    source == "calculated"
  end

  def from_settings?
    source == "from_settings"
  end

  def manual?
    source == "manual"
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current) unless confirmed?
  end

  # Mark value as overridden
  def mark_overridden!
    update!(overridden: true) unless overridden?
  end

  # Update value - marks as overridden if source is calculated
  def update_value!(new_value)
    if calculated? && value != new_value
      update!(value: new_value, overridden: true)
    else
      update!(value: new_value)
    end
  end

  # === Type Casting Helpers ===

  def to_integer
    return 0 if value.blank?

    value.to_i
  end

  def to_decimal
    return BigDecimal("0") if value.blank?

    BigDecimal(value)
  rescue ArgumentError
    BigDecimal("0")
  end

  def to_boolean
    return false if value.blank?

    value.to_s.downcase.in?(%w[true 1 yes])
  end

  # Cast value to appropriate Ruby type based on element conventions
  def typed_value
    return nil if value.blank?

    case infer_type
    when :boolean
      to_boolean
    when :integer
      to_integer
    when :decimal
      to_decimal
    when :date
      Date.parse(value)
    else
      value
    end
  rescue ArgumentError, TypeError
    value
  end

  # Set value with type coercion
  def typed_value=(new_value)
    self.value = new_value.to_s
  end

  # Display-friendly source label
  def source_label
    case source
    when "calculated" then "Calculated"
    when "from_settings" then "From Settings"
    when "manual" then "Manual Entry"
    else source.humanize
    end
  end

  def source_badge_class
    case source
    when "calculated" then "bg-blue-100 text-blue-800"
    when "from_settings" then "bg-purple-100 text-purple-800"
    when "manual" then "bg-green-100 text-green-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  private

  # Infer type from element name conventions or value format
  def infer_type
    # Boolean indicators
    return :boolean if value.to_s.downcase.in?(%w[true false yes no])

    # Decimal indicators (contains decimal point)
    return :decimal if value.to_s.match?(/^\d+\.\d+$/)

    # Integer indicators (pure digits)
    return :integer if value.to_s.match?(/^\d+$/)

    # Date indicators
    return :date if value.to_s.match?(/^\d{4}-\d{2}-\d{2}$/)

    :string
  end
end
