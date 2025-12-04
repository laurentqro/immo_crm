class AddVerificationFieldsToBeneficialOwners < ActiveRecord::Migration[8.1]
  def change
    add_column :beneficial_owners, :source_of_wealth_verified, :boolean, default: false
    add_column :beneficial_owners, :identification_verified, :boolean, default: false
  end
end
