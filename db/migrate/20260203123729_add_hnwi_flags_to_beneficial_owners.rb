class AddHnwiFlagsToBeneficialOwners < ActiveRecord::Migration[8.1]
  def change
    add_column :beneficial_owners, :is_hnwi, :boolean, default: false, null: false
    add_column :beneficial_owners, :is_uhnwi, :boolean, default: false, null: false
    add_column :beneficial_owners, :net_worth_eur, :decimal, precision: 15, scale: 2

    add_index :beneficial_owners, :is_hnwi
    add_index :beneficial_owners, :is_uhnwi
  end
end
