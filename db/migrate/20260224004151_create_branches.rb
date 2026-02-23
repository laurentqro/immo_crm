# frozen_string_literal: true

class CreateBranches < ActiveRecord::Migration[8.0]
  def change
    create_table :branches do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :country, limit: 2, null: false

      t.timestamps
    end
  end
end
