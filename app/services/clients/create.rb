# frozen_string_literal: true

module Clients
  # Creates a client within an organization.
  #
  # Usage:
  #   result = Clients::Create.call(organization: org, params: { name: "Dupont", client_type: "NATURAL_PERSON" })
  #   result.success? # => true
  #   result.record    # => #<Client ...>
  #
  class Create
    def self.call(organization:, params:)
      client = organization.clients.build(params)

      if client.save
        ServiceResult.success(client)
      else
        ServiceResult.from_record(client)
      end
    end
  end
end
