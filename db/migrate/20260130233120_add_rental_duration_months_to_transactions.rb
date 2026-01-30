class AddRentalDurationMonthsToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :rental_duration_months, :integer
  end
end
