# frozen_string_literal: true

class CreateEntityBeneficialOwners < ActiveRecord::Migration[8.0]
  def change
    create_table :entity_beneficial_owners do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :nationality, limit: 2, null: false

      t.timestamps
    end
  end
end
