# frozen_string_literal: true

class AddIntroducerFieldsToClients < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :introduced_by_third_party, :boolean, default: false, null: false
    add_column :clients, :introducer_country, :string

    add_index :clients, :introduced_by_third_party
  end
end
