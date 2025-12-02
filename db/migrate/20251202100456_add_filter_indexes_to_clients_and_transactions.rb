# frozen_string_literal: true

# Adds composite indexes for commonly filtered columns to improve query performance.
# These indexes support the filtering and search operations in list views.
class AddFilterIndexesToClientsAndTransactions < ActiveRecord::Migration[8.1]
  def change
    # Clients: Composite indexes for filtered list views
    add_index :clients, [:organization_id, :client_type], name: "index_clients_on_org_and_type"
    add_index :clients, [:organization_id, :risk_level], name: "index_clients_on_org_and_risk"

    # Transactions: Composite indexes for filtered list views
    add_index :transactions, [:organization_id, :transaction_type], name: "index_transactions_on_org_and_type"

    # STR Reports: Composite index for filtered list views
    add_index :str_reports, [:organization_id, :reason], name: "index_str_reports_on_org_and_reason"
  end
end
