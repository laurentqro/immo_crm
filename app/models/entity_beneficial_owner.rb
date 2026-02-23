# frozen_string_literal: true

# Tracks the reporting entity's own beneficial owners (25%+ ownership or controlling).
# These are NOT client beneficial owners — they describe who owns the real estate agency itself.
# Used by survey field a3306b to compute the nationality breakdown for AMSF reporting.
class EntityBeneficialOwner < ApplicationRecord
  belongs_to :organization

  validates :name, presence: true
  validates :nationality, presence: true, length: {is: 2}
end
