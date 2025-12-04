class AddLockIndexesToSubmissions < ActiveRecord::Migration[8.1]
  def change
    # Add indexes for lock queries (FR-029)
    # Note: locked_by_user_id single index already exists from add_lifecycle_fields migration
    # Composite index improves queries that check both locked_by_user_id AND locked_at
    add_index :submissions, [:locked_by_user_id, :locked_at],
      name: "index_submissions_on_lock_status", if_not_exists: true
    add_index :submissions, :locked_at, if_not_exists: true
  end
end
