# frozen_string_literal: true

class Trustee < ApplicationRecord
  belongs_to :client

  scope :professional, -> { where(is_professional: true) }

  validates :name, presence: true
  validates :nationality, inclusion: {in: ISO3166::Country.codes}, allow_blank: true
  validate :client_must_be_trust

  private

  def client_must_be_trust
    return unless client

    errors.add(:client, "must be a trust") unless client.trust?
  end
end
