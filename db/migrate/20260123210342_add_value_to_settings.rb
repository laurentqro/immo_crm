class AddValueToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :value, :string
  end
end
