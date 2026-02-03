# frozen_string_literal: true

class AddThirdPartyCddToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :third_party_cdd, :boolean, default: false, null: false
    add_column :clients, :third_party_cdd_type, :string
    add_column :clients, :third_party_cdd_country, :string

    add_index :clients, :third_party_cdd
  end
end
