class RemoveDuplicateAmountFromTransactions < ActiveRecord::Migration[8.1]
  def change
    # Remove duplicate 'amount' field - 'transaction_value' already exists
    # and is used by CalculationEngine for monetary calculations
    remove_column :transactions, :amount, :decimal, precision: 15, scale: 2
  end
end
