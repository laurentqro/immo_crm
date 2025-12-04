class AddPerformanceIndexesToComplianceFields < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Indexes for CalculationEngine queries and compliance scopes
    # Using algorithm: :concurrently to avoid table locks on production

    # Client compliance field indexes
    add_index :clients, :country_code, algorithm: :concurrently, if_not_exists: true
    add_index :clients, :residence_status, algorithm: :concurrently, if_not_exists: true
    add_index :clients, :is_pep_related, algorithm: :concurrently, if_not_exists: true
    add_index :clients, :is_pep_associated, algorithm: :concurrently, if_not_exists: true

    # Transaction direction index for by_client/with_client scopes
    add_index :transactions, :direction, algorithm: :concurrently, if_not_exists: true

    # Beneficial owner country index
    add_index :beneficial_owners, :country_code, algorithm: :concurrently, if_not_exists: true
  end
end
