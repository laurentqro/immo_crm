class AddLegalPersonTypeOtherToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :legal_person_type_other, :string
  end
end
