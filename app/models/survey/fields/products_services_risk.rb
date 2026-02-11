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
      include Helpers

      private

      # === Check Payment Statistics ===

      def a2101w
        setting_value("a2101w") || "Non"
      end

      def a2101wrp
        setting_value("a2101wrp") || "Non"
      end

      def a2102w
        year_transactions.with_client.where(payment_method: "CHECK").count
      end

      def a2102bw
        year_transactions.with_client.where(payment_method: "CHECK").sum(:transaction_value)
      end

      def a2101b
        (a2102w.positive? || a2102b.positive?) ? "Oui" : "Non"
      end

      def a2102b
        year_transactions.by_client.where(payment_method: "CHECK").count
      end

      def a2102bb
        year_transactions.by_client.where(payment_method: "CHECK").sum(:transaction_value)
      end

      # === Transfer Payment Statistics ===

      def a2104w
        setting_value("a2104w") || "Oui"
      end

      def a2104wrp
        setting_value("a2104wrp") || "Oui"
      end

      def a2105w
        year_transactions.with_client.where(payment_method: "WIRE").count
      end

      def a2105bw
        year_transactions.with_client.where(payment_method: "WIRE").sum(:transaction_value)
      end

      def a2104b
        (a2105w.positive? || a2105b.positive?) ? "Oui" : "Non"
      end

      def a2105b
        year_transactions.by_client.where(payment_method: "WIRE").count
      end

      def a2105bb
        year_transactions.by_client.where(payment_method: "WIRE").sum(:transaction_value)
      end

      # === Cash Payment Statistics ===

      def a2107w
        setting_value("a2107w") || "Non"
      end

      def a2107wrp
        setting_value("a2107wrp") || "Non"
      end

      def a2108w
        year_transactions.with_client.with_cash.count
      end

      def a2109w
        year_transactions.with_client.with_cash.sum(:cash_amount)
      end

      def ag24010w
        # Total transaction value by property location
        year_transactions.where.not(property_country: [nil, ""]).sum(:transaction_value)
      end

      def a2110w
        year_transactions.with_client.with_cash.where("cash_amount >= ?", 10000).count
      end

      def a2113w
        setting_value("a2113w") || "Oui"
      end

      def a2113aw
        year_transactions
          .with_client
          .with_cash
          .joins(:client)
          .merge(Client.natural_persons)
          .where("cash_amount >= ?", 100000)
          .count
      end

      def a2114a
        year_transactions
          .with_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where(incorporation_country: "MC"))
          .where("cash_amount >= ?", 100000)
          .count
      end

      def a2115aw
        year_transactions
          .with_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where.not(incorporation_country: ["MC", nil, ""]))
          .where("cash_amount >= ?", 100000)
          .count
      end

      def a2107b
        (a2108w.positive? || a2108b.positive?) ? "Oui" : "Non"
      end

      def a2108b
        year_transactions.by_client.with_cash.count
      end

      def a2109b
        year_transactions.by_client.with_cash.sum(:cash_amount)
      end

      def ag24010b
        # Value of transactions by client property location
        year_transactions.by_client.where.not(property_country: [nil, ""]).sum(:transaction_value)
      end

      def a2110b
        year_transactions.by_client.with_cash.where("cash_amount >= ?", 10000).count
      end

      def a2113b
        setting_value("a2113b") || "Oui"
      end

      def a2113ab
        year_transactions
          .by_client
          .with_cash
          .joins(:client)
          .merge(Client.natural_persons)
          .where("cash_amount >= ?", 100000)
          .count
      end

      def a2114ab
        year_transactions
          .by_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where(incorporation_country: "MC"))
          .where("cash_amount >= ?", 100000)
          .count
      end

      def a2115ab
        year_transactions
          .by_client
          .with_cash
          .joins(:client)
          .merge(Client.legal_entities.where.not(incorporation_country: ["MC", nil, ""]))
          .where("cash_amount >= ?", 100000)
          .count
      end

      # === Cryptocurrency Statistics ===

      def a2201a
        setting_value("a2201a") || "Non"
      end

      def a2201d
        setting_value("a2201d") || "Non"
      end

      def a2202
        year_transactions.where(payment_method: "CRYPTO").exists? ? "Oui" : "Non"
      end

      def a2203
        setting_value("a2203")
      end

      def ac1616c
        year_transactions.where(payment_method: "CRYPTO").exists? ? "Oui" : "Non"
      end

      def ac1621
        setting_value("ac1621")
      end

      # === French-labeled transaction fields (ir_*) ===

      # Transaction counts for specific regulatory questions
      def air233b
        # Purchases where agency represents buyer
        year_transactions.purchases.where(agency_role: "BUYER_AGENT").count
      end

      def air233s
        # Sales where agency represents seller
        year_transactions.sales.where(agency_role: "SELLER_AGENT").count
      end

      def air235b_2
        # Purchase/sale transactions where agency represented client
        year_transactions.where(transaction_type: %w[PURCHASE SALE]).count
      end

      def air235s
        # Sales transactions count
        year_transactions.sales.count
      end

      def air117
        # Specific count (new construction purchases)
        year_transactions.purchases.where(is_new_construction: true).count
      end

      def air2391
        # Was there preemption activity?
        setting_value("air2391") || "Non"
      end

      def air2392
        # Number of preemptions
        setting_value("air2392")&.to_i || 0
      end

      def air2393
        # Value of preempted properties
        setting_value("air2393")&.to_d || 0
      end

      # Q162: Total unique rental properties during the reporting period
      # Uses ManagedProperty model for accurate property-level tracking
      def air234
        organization.managed_properties.active_in_year(year).count
      end

      def air236
        # Another transaction count category
        year_transactions.rentals.count
      end

      def air2313
        # Unique rental properties with monthly rent > 10,000
        year_transactions
          .rentals
          .where("rental_annual_value > ?", 120000)  # > 10k/month = > 120k/year
          .select(:client_id)
          .distinct
          .count
      end

      def air2316
        # Unique rental properties with monthly rent <= 10,000
        year_transactions
          .rentals
          .where("rental_annual_value <= ? OR rental_annual_value IS NULL", 120000)
          .select(:client_id)
          .distinct
          .count
      end

      # === Section Comments ===

      def a2501a
        setting_value("a2501a").present? ? "Oui" : "Non"
      end

      def a2501
        setting_value("a2501")
      end

      # === Additional Transaction Dimensional Fields ===

      def air233
        # Total transactions where agency acted as agent, grouped by property country
        year_transactions
          .where.not(agency_role: [nil, ""])
          .where.not(property_country: [nil, ""])
          .group(:property_country)
          .count
      end

      # Purchase/sale transactions by clients, grouped by client country
      # All property transactions are BY_CLIENT type (client-to-third-party payments)
      # Natural persons: group by nationality
      # Legal entities: group by incorporation_country
      def air235b_1
        # Natural persons: group by nationality
        natural_counts = year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .merge(Client.natural_persons)
          .where.not(clients: {nationality: [nil, ""]})
          .group("clients.nationality")
          .count

        # Legal entities: group by incorporation_country
        legal_counts = year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .merge(Client.legal_entities)
          .where.not(clients: {incorporation_country: [nil, ""]})
          .group("clients.incorporation_country")
          .count

        # Merge both Hashes, summing counts for overlapping countries
        natural_counts.merge(legal_counts) { |_key, v1, v2| v1 + v2 }
      end

      # Rental transactions, grouped by property country
      def air237b
        year_transactions.rentals
          .where.not(property_country: [nil, ""])
          .group(:property_country)
          .count
      end

      # Rental transaction values, grouped by property country
      def air238b
        year_transactions.rentals
          .where.not(property_country: [nil, ""])
          .group(:property_country)
          .sum(:transaction_value)
      end

      # Additional rental value metric, grouped by property country
      def air239b
        year_transactions.rentals
          .where.not(property_country: [nil, ""])
          .group(:property_country)
          .sum(:rental_annual_value)
      end
    end
  end
end
