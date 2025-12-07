class AddGinIndexToSubmissionValuesMetadata < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :submission_values, :metadata, using: :gin, algorithm: :concurrently
  end
end
