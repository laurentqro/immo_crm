class RemoveDeprecatedColumnsFromSettings < ActiveRecord::Migration[8.1]
  def change
    remove_index :settings, :xbrl_element, if_exists: true
    remove_column :settings, :value_type, :string
    remove_column :settings, :xbrl_element, :string
  end
end
