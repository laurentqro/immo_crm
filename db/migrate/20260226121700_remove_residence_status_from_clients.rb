class RemoveResidenceStatusFromClients < ActiveRecord::Migration[8.0]
  def change
    remove_index :clients, :residence_status, if_exists: true
    remove_column :clients, :residence_status, :string
  end
end
