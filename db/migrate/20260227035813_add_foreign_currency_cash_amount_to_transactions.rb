class AddForeignCurrencyCashAmountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :foreign_currency_cash_amount, :decimal, precision: 15, scale: 2
  end
end
