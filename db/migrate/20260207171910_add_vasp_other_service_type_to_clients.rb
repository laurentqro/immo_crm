class AddVaspOtherServiceTypeToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :vasp_other_service_type, :string
  end
end
