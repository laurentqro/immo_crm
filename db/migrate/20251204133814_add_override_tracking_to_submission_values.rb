class AddOverrideTrackingToSubmissionValues < ActiveRecord::Migration[8.1]
  def change
    add_column :submission_values, :override_reason, :text
    add_column :submission_values, :override_user_id, :bigint
    add_column :submission_values, :previous_year_value, :string

    add_foreign_key :submission_values, :users, column: :override_user_id, on_delete: :nullify
    add_index :submission_values, :override_user_id
  end
end
