# frozen_string_literal: true

# Tab 2: Products/Services Risk Assessment
# Field methods for products and services risk metrics
#
# Fields cover:
# - Real estate transaction statistics (sales, purchases, rentals)
# - Property type and location breakdowns
# - Payment method statistics (checks, transfers, cash, crypto)
# - High-value transaction tracking
# - Preemption and specific transaction types
#
class Survey
  module Fields
    module ProductsServicesRisk
      extend ActiveSupport::Concern

      private

      # === Check Payment Statistics ===

      def accepts_checks
        setting_value("accepts_checks") || "Non"
      end

      def accepted_checks_period
        setting_value("accepted_checks_period") || "Non"
      end

      def check_transactions_with_clients
        year_transactions.with_client.where(payment_method: "CHECK").count
      end

      def check_value_with_clients
        year_transactions.with_client.where(payment_method: "CHECK").sum(:transaction_value)
      end

      def clients_used_checks
        (check_transactions_with_clients.positive? || check_transactions_by_clients.positive?) ? "Oui" : "Non"
      end

      def check_transactions_by_clients
        year_transactions.by_client.where(payment_method: "CHECK").count
      end

      def check_value_by_clients
        year_transactions.by_client.where(payment_method: "CHECK").sum(:transaction_value)
      end

      # === Transfer Payment Statistics ===

      def accepts_transfers
        setting_value("accepts_transfers") || "Oui"
      end

      def accepted_transfers_period
        setting_value("accepted_transfers_period") || "Oui"
      end

      def transfer_transactions_with_clients
        year_transactions.with_client.where(payment_method: "WIRE").count
      end

      def transfer_value_with_clients
        year_transactions.with_client.where(payment_method: "WIRE").sum(:transaction_value)
      end

      def clients_used_transfers
        (transfer_transactions_with_clients.positive? || transfer_transactions_by_clients.positive?) ? "Oui" : "Non"
      end

      def transfer_transactions_by_clients
        year_transactions.by_client.where(payment_method: "WIRE").count
      end

      def transfer_value_by_clients
        year_transactions.by_client.where(payment_method: "WIRE").sum(:transaction_value)
      end

      # === Cash Payment Statistics ===

      def accepts_cash
        setting_value("accepts_cash") || "Non"
      end

      def accepted_cash_period
        setting_value("accepted_cash_period") || "Non"
      end

      def cash_transactions_with_clients
        year_transactions.with_client.with_cash.count
      end

      def cash_value_with_clients
        year_transactions.with_client.with_cash.sum(:cash_amount)
      end

      def transactions_by_property_location
        # Total transaction value by property location
        year_transactions.where.not(property_country: [nil, ""]).sum(:transaction_value)
      end

      def cash_over_10k_with_clients
        year_transactions.with_client.with_cash.where("cash_amount >= ?", 10000).count
      end

      def can_identify_cash_over_100k_with
        setting_value("can_identify_cash_over_100k_with") || "Oui"
      end

      def cash_over_100k_individuals_with
        year_transactions
          .with_client
          .with_cash
          .joins(:client)
          .merge(Client.natural_persons)
          .where("cash_amount >= ?", 100000)
          .count
      end

      def cash_over_100k_monaco_entities_with
        year_transactions
          .with_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where(country_code: "MC"))
          .where("cash_amount >= ?", 100000)
          .count
      end

      def cash_over_100k_foreign_entities_with
        year_transactions
          .with_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where.not(country_code: ["MC", nil, ""]))
          .where("cash_amount >= ?", 100000)
          .count
      end

      def clients_used_cash
        (cash_transactions_with_clients.positive? || cash_transactions_by_clients.positive?) ? "Oui" : "Non"
      end

      def cash_transactions_by_clients
        year_transactions.by_client.with_cash.count
      end

      def cash_value_by_clients
        year_transactions.by_client.with_cash.sum(:cash_amount)
      end

      def clients_by_property_location
        # Value of transactions by client property location
        year_transactions.by_client.where.not(property_country: [nil, ""]).sum(:transaction_value)
      end

      def cash_over_10k_by_clients
        year_transactions.by_client.with_cash.where("cash_amount >= ?", 10000).count
      end

      def can_identify_cash_over_100k_by
        setting_value("can_identify_cash_over_100k_by") || "Oui"
      end

      def cash_over_100k_individuals_by
        year_transactions
          .by_client
          .with_cash
          .joins(:client)
          .merge(Client.natural_persons)
          .where("cash_amount >= ?", 100000)
          .count
      end

      def cash_over_100k_monaco_entities_by
        year_transactions
          .by_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where(country_code: "MC"))
          .where("cash_amount >= ?", 100000)
          .count
      end

      def cash_over_100k_foreign_entities_by
        year_transactions
          .by_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where.not(country_code: ["MC", nil, ""]))
          .where("cash_amount >= ?", 100000)
          .count
      end

      # === Cryptocurrency Statistics ===

      def accepts_cryptocurrency
        setting_value("accepts_cryptocurrency") || "Non"
      end

      def plans_virtual_currency
        setting_value("plans_virtual_currency") || "Non"
      end

      def has_virtual_asset_relationships
        year_transactions.where(payment_method: "CRYPTO").exists? ? "Oui" : "Non"
      end

      def virtual_asset_platforms
        setting_value("virtual_asset_platforms")
      end

      def crypto_transactions
        year_transactions.where(payment_method: "CRYPTO").exists? ? "Oui" : "Non"
      end

      def verifies_virtual_asset_bo
        setting_value("verifies_virtual_asset_bo")
      end

      # === French-labeled transaction fields (ir_*) ===

      # Transaction counts for specific regulatory questions
      def ir_233b
        # Purchases where agency represents buyer
        year_transactions.purchases.where(agency_role: "BUYER_AGENT").count
      end

      def ir_233s
        # Sales where agency represents seller
        year_transactions.sales.where(agency_role: "SELLER_AGENT").count
      end

      def pour_combien_d_achats_ventes_avez_vous_represente
        # Purchase/sale transactions where agency represented client
        year_transactions.where(transaction_type: %w[PURCHASE SALE]).count
      end

      def ir_235s
        # Sales transactions count
        year_transactions.sales.count
      end

      def ir_117
        # Specific count (new construction purchases)
        year_transactions.purchases.where(is_new_construction: true).count
      end

      def ir_2391
        # Was there preemption activity?
        setting_value("ir_2391") || "Non"
      end

      def ir_2392
        # Number of preemptions
        setting_value("ir_2392")&.to_i || 0
      end

      def quelle_etait_value_biens_preemptes_iso4217_eur
        # Value of preempted properties
        setting_value("quelle_etait_value_biens_preemptes_iso4217_eur")&.to_d || 0
      end

      def ir_234
        # Transaction count for specific category
        year_transactions.purchases.count
      end

      def ir_236
        # Another transaction count category
        year_transactions.rentals.count
      end

      def count_biens_locatifs_uniques_gt_10_000_par_mois_qu
        # Unique rental properties with monthly rent > 10,000
        year_transactions
          .rentals
          .where("rental_annual_value > ?", 120000)  # > 10k/month = > 120k/year
          .select(:client_id)
          .distinct
          .count
      end

      def count_biens_locatifs_uniques_lt_10_000_par_mois_qu
        # Unique rental properties with monthly rent <= 10,000
        year_transactions
          .rentals
          .where("rental_annual_value <= ? OR rental_annual_value IS NULL", 120000)
          .select(:client_id)
          .distinct
          .count
      end

      # === Section Comments ===

      def section_comments_payments_alt
        setting_value("section_comments_payments_alt").present? ? "Oui" : "Non"
      end

      def section_comments_payments
        setting_value("section_comments_payments")
      end

      # === Additional Transaction Dimensional Fields ===

      def ir_233
        # Total transactions where agency acted as agent
        year_transactions.where.not(agency_role: [nil, ""]).count
      end

      def count_transactions_effectuees_par_les_clients_vent
        # Sales transactions by clients
        year_transactions.by_client.sales.count
      end

      def ir_237b
        # Rental transactions count (alternative)
        year_transactions.rentals.count
      end

      def ir_238b
        # Rental transaction values
        year_transactions.rentals.sum(:transaction_value)
      end

      def ir_239b
        # Additional rental value metric
        year_transactions.rentals.sum(:rental_annual_value)
      end
    end
  end
end
