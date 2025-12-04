class AddSourceConfirmedIndexToSubmissionValues < ActiveRecord::Migration[8.1]
  def change
    # Composite index for from_settings.unconfirmed query pattern:
    # submission.submission_values.from_settings.unconfirmed
    # WHERE submission_id = ? AND source = 'from_settings' AND confirmed_at IS NULL
    add_index :submission_values, [:submission_id, :source, :confirmed_at],
      name: "index_submission_values_on_source_confirmation"
  end
end
