# frozen_string_literal: true

# Tracks the reporting entity's branches, subsidiaries, and agencies.
# Used by survey fields a3302 (has branches?), a3303 (by country), and a3306 (foreign count).
class Branch < ApplicationRecord
  belongs_to :organization

  validates :name, presence: true
  validates :country, presence: true, length: {is: 2}

  scope :foreign, -> { where.not(country: "MC") }
end
