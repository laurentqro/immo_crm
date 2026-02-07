# frozen_string_literal: true

# Setting stores organization-wide configuration as key-value pairs.
# Settings are grouped by category and can have different value types.
#
# == Schema
#   organization_id: integer (FK)
#   key:            string (unique per org)
#   category:       enum - entity_info|kyc_procedures|compliance_policies|training
#
# == Usage
#   setting = organization.settings.find_by(key: "entity_name")
#   setting.value      # => "Agence Immobilière Monaco"
#
class Setting < ApplicationRecord
  # Valid categories matching AMSF compliance sections
  CATEGORIES = %w[entity_info kyc_procedures compliance_policies training controls].freeze

  belongs_to :organization

  validates :key, presence: true, uniqueness: { scope: :organization_id }
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  # === Scopes ===

  scope :by_category, ->(category) { where(category: category) }
  scope :for_organization, ->(org) { where(organization: org) }
end
