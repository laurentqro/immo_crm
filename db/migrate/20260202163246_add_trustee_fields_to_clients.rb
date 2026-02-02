class AddTrusteeFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :trustee_name, :string
    add_column :clients, :trustee_nationality, :string
    add_column :clients, :trustee_country, :string
    add_column :clients, :is_professional_trustee, :boolean, default: false
  end
end
