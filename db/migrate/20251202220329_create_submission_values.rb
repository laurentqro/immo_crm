class CreateSubmissionValues < ActiveRecord::Migration[8.1]
  def change
    create_table :submission_values do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :element_name, null: false
      t.string :value
      t.string :source, null: false
      t.boolean :overridden, default: false
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :submission_values, [:submission_id, :element_name], unique: true
  end
end
