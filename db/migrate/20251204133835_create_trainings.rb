class CreateTrainings < ActiveRecord::Migration[8.1]
  def change
    create_table :trainings do |t|
      t.references :organization, null: false, foreign_key: true
      t.date :training_date, null: false
      t.string :training_type, null: false
      t.string :topic, null: false
      t.string :provider, null: false
      t.integer :staff_count, null: false
      t.decimal :duration_hours, precision: 4, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :trainings, [:organization_id, :training_date]
    add_index :trainings, :training_type
  end
end
