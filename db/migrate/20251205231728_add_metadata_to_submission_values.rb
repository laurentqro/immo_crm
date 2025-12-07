class AddMetadataToSubmissionValues < ActiveRecord::Migration[8.1]
  def change
    add_column :submission_values, :metadata, :jsonb, default: {}
  end
end
