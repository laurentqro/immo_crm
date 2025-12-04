class CreateManagedProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :managed_properties do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :property_address, null: false
      t.string :property_type, default: "RESIDENTIAL"
      t.date :management_start_date, null: false
      t.date :management_end_date
      t.decimal :monthly_rent, precision: 15, scale: 2
      t.decimal :management_fee_percent, precision: 5, scale: 2
      t.decimal :management_fee_fixed, precision: 15, scale: 2
      t.string :tenant_name
      t.string :tenant_type
      t.string :tenant_country, limit: 2
      t.boolean :tenant_is_pep, default: false, null: false
      t.text :notes

      t.timestamps
    end

    add_index :managed_properties, [:organization_id, :management_end_date],
              name: "idx_managed_props_org_active"
    add_index :managed_properties, :management_start_date
  end
end
