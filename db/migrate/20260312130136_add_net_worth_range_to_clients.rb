class AddNetWorthRangeToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :net_worth_range, :string
  end
end
