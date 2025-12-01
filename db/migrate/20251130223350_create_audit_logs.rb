class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      # Allow null for auth events before login
      # Use on_delete: :nullify to preserve audit records when org/user is deleted (compliance)
      t.references :organization, foreign_key: { on_delete: :nullify }
      # Allow null for system events
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :action, null: false
      # Allow null for non-model events (e.g., login)
      t.references :auditable, polymorphic: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    # Optimize common queries
    add_index :audit_logs, [:organization_id, :created_at]
    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :action
  end
end
