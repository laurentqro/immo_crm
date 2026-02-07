# frozen_string_literal: true

class AddIndexOnLegalEntityTypeToClients < ActiveRecord::Migration[8.1]
  def change
    add_index :clients, :legal_entity_type
  end
end
