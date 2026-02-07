# frozen_string_literal: true

class Trustee < ApplicationRecord
  belongs_to :client

  validates :name, presence: true
  validates :nationality, format: {with: /\A[A-Z]{2}\z/, message: "must be ISO 3166-1 alpha-2 format"}, allow_blank: true
  validate :client_must_be_trust

  private

  def client_must_be_trust
    return unless client

    errors.add(:client, "must be a trust") unless client.trust?
  end
end
