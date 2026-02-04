class RemoveHnwiFlagsFromBeneficialOwners < ActiveRecord::Migration[8.1]
  def change
    # Remove boolean flags that are now derived from net_worth_eur
    # HNWI/UHNWI status is calculated using thresholds:
    # - HNWI: net_worth_eur > 5,000,000
    # - UHNWI: net_worth_eur > 50,000,000
    # This ensures UHNWI ⊂ HNWI (required by AMSF XBRL validation)
    remove_index :beneficial_owners, :is_hnwi
    remove_index :beneficial_owners, :is_uhnwi
    remove_column :beneficial_owners, :is_hnwi, :boolean, default: false, null: false
    remove_column :beneficial_owners, :is_uhnwi, :boolean, default: false, null: false
  end
end
