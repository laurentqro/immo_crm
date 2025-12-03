class AddComplianceFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :is_pep_related, :boolean, default: false, null: false
    add_column :clients, :is_pep_associated, :boolean, default: false, null: false
    add_column :clients, :country_code, :string
    add_column :clients, :residence_status, :string
  end
end
