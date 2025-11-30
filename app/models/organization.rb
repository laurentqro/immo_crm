# frozen_string_literal: true

# Organization extends Jumpstart Pro Account with AMSF-specific fields.
# Each Account has one Organization that stores Monaco business registry info.
class Organization < ApplicationRecord
  include AmsfConstants

  belongs_to :account

  # Future associations - will be added as models are created
  # has_many :clients, dependent: :destroy
  # has_many :transactions, dependent: :destroy
  # has_many :submissions, dependent: :destroy
  # has_many :str_reports, dependent: :destroy
  # has_many :settings, dependent: :destroy
  # has_many :audit_logs, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :rci_number, presence: true, uniqueness: true,
                         format: { with: /\A[A-Za-z0-9]+\z/, message: "must be alphanumeric" }
  validates :country, length: { is: 2 }, allow_blank: true

  # Scopes for future use
  scope :by_country, ->(country) { where(country: country) }
end
