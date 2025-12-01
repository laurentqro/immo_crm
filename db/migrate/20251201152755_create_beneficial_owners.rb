# frozen_string_literal: true

class CreateBeneficialOwners < ActiveRecord::Migration[8.1]
  def change
    create_table :beneficial_owners do |t|
      t.references :client, null: false, foreign_key: true

      # Basic info
      t.string :name, null: false
      t.string :nationality               # ISO 3166-1 alpha-2
      t.string :residence_country         # ISO 3166-1 alpha-2

      # Ownership details
      t.decimal :ownership_pct, precision: 5, scale: 2  # 0.00 - 100.00
      t.string :control_type              # DIRECT, INDIRECT, REPRESENTATIVE

      # PEP (Politically Exposed Person)
      t.boolean :is_pep, default: false, null: false
      t.string :pep_type                  # DOMESTIC, FOREIGN, INTL_ORG

      t.timestamps
    end

    # Indexes
    # Note: client_id index created automatically by t.references
    add_index :beneficial_owners, :is_pep
  end
end
