class AddLifecycleFieldsToSubmissions < ActiveRecord::Migration[8.1]
  def change
    add_column :submissions, :current_step, :integer, default: 1
    add_column :submissions, :locked_by_user_id, :bigint
    add_column :submissions, :locked_at, :datetime
    add_column :submissions, :generated_at, :datetime
    add_column :submissions, :reopened_count, :integer, default: 0, null: false

    add_foreign_key :submissions, :users, column: :locked_by_user_id, on_delete: :nullify
    add_index :submissions, :locked_by_user_id
  end
end
