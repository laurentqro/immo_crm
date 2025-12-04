class ChangeIsPopRelatedColumnsToNullable < ActiveRecord::Migration[8.1]
  def change
    # Change PEP-related boolean fields to nullable to distinguish
    # "not yet assessed" (NULL) from "assessed as not PEP-related" (false)
    change_column_null :clients, :is_pep_related, true
    change_column_null :clients, :is_pep_associated, true
    change_column_default :clients, :is_pep_related, from: false, to: nil
    change_column_default :clients, :is_pep_associated, from: false, to: nil
  end
end
