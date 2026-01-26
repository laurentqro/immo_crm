# frozen_string_literal: true

class DropSubmissionValues < ActiveRecord::Migration[8.1]
  def up
    drop_table :submission_values
  end

  def down
    create_table :submission_values do |t|
      t.datetime :confirmed_at
      t.string :element_name, null: false
      t.jsonb :metadata, default: {}
      t.boolean :overridden, default: false
      t.text :override_reason
      t.bigint :override_user_id
      t.string :previous_year_value
      t.string :source, null: false
      t.references :submission, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end

    add_index :submission_values, [:submission_id, :element_name], unique: true
    add_index :submission_values, :metadata, using: :gin
    add_index :submission_values, :override_user_id
    add_index :submission_values, [:submission_id, :source, :confirmed_at], name: "index_submission_values_on_source_confirmation"
    add_foreign_key :submission_values, :users, column: :override_user_id, on_delete: :nullify
  end
end
