# frozen_string_literal: true

class SimplifySubmissions < ActiveRecord::Migration[8.1]
  def change
    # Remove foreign key first (must happen before column removal)
    remove_foreign_key :submissions, :users, column: :locked_by_user_id, if_exists: true

    # Remove indexes
    remove_index :submissions, name: "index_submissions_on_locked_at", if_exists: true
    remove_index :submissions, name: "index_submissions_on_lock_status", if_exists: true
    remove_index :submissions, name: "index_submissions_on_locked_by_user_id", if_exists: true

    # Remove unused columns
    remove_column :submissions, :current_step, :integer, default: 1
    remove_column :submissions, :downloaded_unvalidated, :boolean, default: false
    remove_column :submissions, :generated_at, :datetime
    remove_column :submissions, :locked_at, :datetime
    remove_column :submissions, :locked_by_user_id, :bigint
    remove_column :submissions, :reopened_count, :integer, default: 0, null: false
    remove_column :submissions, :signatory_name, :string
    remove_column :submissions, :signatory_title, :string
  end
end
