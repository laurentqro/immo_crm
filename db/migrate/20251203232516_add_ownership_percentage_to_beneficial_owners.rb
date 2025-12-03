class AddOwnershipPercentageToBeneficialOwners < ActiveRecord::Migration[8.1]
  def change
    add_column :beneficial_owners, :ownership_percentage, :decimal, precision: 5, scale: 2
  end
end
