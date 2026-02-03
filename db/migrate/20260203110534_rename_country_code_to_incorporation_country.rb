class RenameCountryCodeToIncorporationCountry < ActiveRecord::Migration[8.1]
  def change
    # Rename on clients table - used for legal entities and trusts
    rename_column :clients, :country_code, :incorporation_country

    # Rename on beneficial_owners table - tracks where beneficial owner entities are incorporated
    rename_column :beneficial_owners, :country_code, :incorporation_country
  end
end
