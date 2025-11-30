# Change audit_logs FK behavior to preserve audit records when users are deleted.
# For compliance, audit logs must be retained for 5 years even if users are removed.
class ChangeAuditLogsUserFkToNullify < ActiveRecord::Migration[8.1]
  def change
    # Remove existing FK that prevents user deletion
    remove_foreign_key :audit_logs, :users

    # Add FK with on_delete: :nullify so audit records are kept but user_id is set to null
    add_foreign_key :audit_logs, :users, on_delete: :nullify
  end
end
