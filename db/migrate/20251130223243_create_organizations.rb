class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.references :account, null: false, foreign_key: true, index: {unique: true}
      t.string :name, null: false
      t.string :rci_number, null: false
      t.string :country, default: "MC"

      t.timestamps
    end

    add_index :organizations, :rci_number, unique: true
  end
end
