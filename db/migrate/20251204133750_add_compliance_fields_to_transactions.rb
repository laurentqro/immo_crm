class AddComplianceFieldsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :property_type, :string
    add_column :transactions, :is_new_construction, :boolean, default: false
    add_column :transactions, :counterparty_is_pep, :boolean, default: false
    add_column :transactions, :counterparty_country, :string, limit: 2
    add_column :transactions, :rental_annual_value, :decimal, precision: 15, scale: 2
    add_column :transactions, :rental_tenant_type, :string

    add_index :transactions, :property_type
    add_index :transactions, :counterparty_country
  end
end
