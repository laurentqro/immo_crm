class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :reference                                     # User's reference number (optional)
      t.date :transaction_date, null: false
      t.string :transaction_type, null: false                 # PURCHASE, SALE, RENTAL
      t.decimal :transaction_value, precision: 15, scale: 2
      t.decimal :commission_amount, precision: 15, scale: 2
      t.string :property_country, default: "MC"
      t.string :payment_method                                # WIRE, CASH, CHECK, CRYPTO, MIXED
      t.decimal :cash_amount, precision: 15, scale: 2
      t.string :agency_role                                   # BUYER_AGENT, SELLER_AGENT, DUAL_AGENT
      t.string :purchase_purpose                              # RESIDENCE, INVESTMENT (for purchases)
      t.text :notes
      t.datetime :deleted_at                                  # Soft delete for compliance

      t.timestamps
    end

    add_index :transactions, :transaction_date
    add_index :transactions, :transaction_type
    add_index :transactions, :deleted_at
    add_index :transactions, [:organization_id, :transaction_date]
  end
end
