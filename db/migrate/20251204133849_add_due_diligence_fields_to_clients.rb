class AddDueDiligenceFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :due_diligence_level, :string
    add_column :clients, :simplified_dd_reason, :text
    add_column :clients, :relationship_end_reason, :string
    add_column :clients, :professional_category, :string
    add_column :clients, :source_of_funds_verified, :boolean, default: false
    add_column :clients, :source_of_wealth_verified, :boolean, default: false

    add_index :clients, :due_diligence_level
    add_index :clients, :professional_category
  end
end
