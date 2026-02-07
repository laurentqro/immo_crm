# frozen_string_literal: true

class RemoveTrusteeFieldsFromClients < ActiveRecord::Migration[8.1]
  def change
    remove_column :clients, :trustee_name, :string
    remove_column :clients, :trustee_nationality, :string
    remove_column :clients, :trustee_country, :string
    remove_column :clients, :is_professional_trustee, :boolean, default: false
  end
end
