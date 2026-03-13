# frozen_string_literal: true

module Clients
  # Updates an existing client.
  #
  # Usage:
  #   result = Clients::Update.call(client: client, params: { name: "New Name" })
  #
  class Update
    def self.call(client:, params:)
      if client.update(params)
        ServiceResult.success(client)
      else
        ServiceResult.from_record(client)
      end
    end
  end
end
