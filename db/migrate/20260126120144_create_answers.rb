# frozen_string_literal: true

class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :submission, null: false, foreign_key: true
      t.string :xbrl_id, null: false
      t.text :value

      t.timestamps
    end

    add_index :answers, [:submission_id, :xbrl_id], unique: true
  end
end
