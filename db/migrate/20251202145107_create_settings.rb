class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :key, null: false
      t.string :value
      t.string :value_type, null: false
      t.string :xbrl_element
      t.string :category, null: false

      t.timestamps
    end

    add_index :settings, [:organization_id, :key], unique: true
    add_index :settings, :category
    add_index :settings, :xbrl_element
  end
end
