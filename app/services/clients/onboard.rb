# frozen_string_literal: true

module Clients
  # Onboards a client with optional beneficial owners in a single transaction.
  # This is the primary entry point for AI agents creating clients with full KYC data.
  #
  # Usage:
  #   result = Clients::Onboard.call(
  #     organization: org,
  #     client_params: { name: "Dupont SA", client_type: "LEGAL_ENTITY", legal_person_type: "SARL" },
  #     beneficial_owners: [
  #       { name: "Jean Dupont", ownership_percentage: 60, control_type: "DIRECT" },
  #       { name: "Marie Dupont", ownership_percentage: 40, control_type: "DIRECT" }
  #     ]
  #   )
  #
  class Onboard
    def self.call(organization:, client_params:, beneficial_owners: [])
      new(organization: organization, client_params: client_params, beneficial_owners: beneficial_owners).call
    end

    def initialize(organization:, client_params:, beneficial_owners:)
      @organization = organization
      @client_params = client_params
      @beneficial_owners = beneficial_owners
    end

    def call
      client = nil

      ActiveRecord::Base.transaction do
        client = @organization.clients.build(@client_params)

        unless client.save
          return ServiceResult.from_record(client)
        end

        if @beneficial_owners.any? && !client.can_have_beneficial_owners?
          client.errors.add(:base, "Natural persons cannot have beneficial owners")
          raise ActiveRecord::Rollback
        end

        @beneficial_owners.each do |owner_params|
          owner = client.beneficial_owners.build(owner_params)
          unless owner.save
            owner.errors.full_messages.each { |msg| client.errors.add(:beneficial_owners, msg) }
            raise ActiveRecord::Rollback
          end
        end
      end

      if client.errors.any?
        ServiceResult.failure(record: client, errors: client.errors.full_messages)
      else
        ServiceResult.success(client.reload)
      end
    end
  end
end
