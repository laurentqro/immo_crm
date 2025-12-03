class CreateSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :submissions do |t|
      t.references :organization, null: false, foreign_key: true
      t.integer :year, null: false
      t.string :taxonomy_version, default: "2025"
      t.string :status, default: "draft"
      t.datetime :started_at
      t.datetime :validated_at
      t.datetime :completed_at
      t.boolean :downloaded_unvalidated, default: false

      t.timestamps
    end

    add_index :submissions, [:organization_id, :year], unique: true
  end
end
