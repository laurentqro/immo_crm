# frozen_string_literal: true

class CreateTrustees < ActiveRecord::Migration[8.1]
  def change
    create_table :trustees do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.string :nationality
      t.boolean :is_professional, default: false, null: false
      t.timestamps
    end
  end
end
