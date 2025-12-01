# frozen_string_literal: true

class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :organization, null: false, foreign_key: true

      # Basic info
      t.string :name, null: false
      t.string :client_type, null: false  # PP, PM, TRUST
      t.string :nationality               # ISO 3166-1 alpha-2
      t.string :residence_country         # ISO 3166-1 alpha-2

      # PEP (Politically Exposed Person)
      t.boolean :is_pep, default: false, null: false
      t.string :pep_type                  # DOMESTIC, FOREIGN, INTL_ORG

      # Risk assessment
      t.string :risk_level                # LOW, MEDIUM, HIGH

      # VASP (Virtual Asset Service Provider)
      t.boolean :is_vasp, default: false, null: false
      t.string :vasp_type                 # CUSTODIAN, EXCHANGE, ICO, OTHER

      # Legal entity fields (PM only)
      t.string :legal_person_type         # SCI, SARL, SAM, SNC, SA, OTHER
      t.string :business_sector           # Industry classification

      # Relationship tracking
      t.datetime :became_client_at
      t.datetime :relationship_ended_at   # For 5-year retention calculation

      # Rejection
      t.string :rejection_reason          # AML_CFT, OTHER

      # Notes
      t.text :notes

      # Soft delete (Discard gem)
      t.datetime :deleted_at

      t.timestamps
    end

    # Indexes for common queries
    # Note: organization_id index created automatically by t.references
    add_index :clients, :client_type
    add_index :clients, :is_pep
    add_index :clients, :risk_level
    add_index :clients, :deleted_at
    add_index :clients, [:organization_id, :deleted_at]
  end
end
