class RenameRentalDurationMonthsToYears < ActiveRecord::Migration[8.1]
  def change
    rename_column :transactions, :rental_duration_months, :rental_duration_years
  end
end
