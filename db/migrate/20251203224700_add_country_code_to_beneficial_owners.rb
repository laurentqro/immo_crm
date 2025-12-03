class AddCountryCodeToBeneficialOwners < ActiveRecord::Migration[8.1]
  def change
    add_column :beneficial_owners, :country_code, :string
  end
end
