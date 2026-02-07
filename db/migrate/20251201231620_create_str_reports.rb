class CreateStrReports < ActiveRecord::Migration[8.1]
  def change
    create_table :str_reports do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, foreign_key: true                   # Optional - may not have identified client
      t.references :transaction, foreign_key: {to_table: :transactions} # Optional - may not be transaction-related
      t.date :report_date, null: false
      t.string :reason, null: false                             # CASH, PEP, UNUSUAL_PATTERN, OTHER
      t.text :notes
      t.datetime :deleted_at                                    # Soft delete for compliance

      t.timestamps
    end

    add_index :str_reports, :report_date
    add_index :str_reports, :reason
    add_index :str_reports, :deleted_at
    add_index :str_reports, [:organization_id, :report_date]
  end
end
