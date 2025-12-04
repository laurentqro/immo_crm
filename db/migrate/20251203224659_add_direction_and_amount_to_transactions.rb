class AddDirectionAndAmountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :direction, :string
    add_column :transactions, :amount, :decimal, precision: 15, scale: 2
  end
end
