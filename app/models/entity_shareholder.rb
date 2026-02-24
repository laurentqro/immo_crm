# frozen_string_literal: true

# Tracks the reporting entity's own shareholders with 25%+ ownership.
# These are NOT client shareholders — they describe who holds shares in the real estate agency itself.
# Used by survey field a3306a to compute the nationality/country breakdown for AMSF reporting.
#
# Distinct from EntityBeneficialOwner: shareholders hold shares directly,
# while beneficial owners may also control indirectly or act as legal representatives.
class EntityShareholder < ApplicationRecord
  belongs_to :organization

  validates :name, presence: true
  validates :nationality, presence: true, length: {is: 2}
end
