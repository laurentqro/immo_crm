class AddLockIndexesToSubmissions < ActiveRecord::Migration[8.1]
  def change
    # Add indexes for lock queries (FR-029)
    add_index :submissions, :locked_by_user_id, if_not_exists: true
    add_index :submissions, :locked_at, if_not_exists: true
  end
end
