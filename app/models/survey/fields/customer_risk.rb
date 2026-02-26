# frozen_string_literal: true

class Survey
  module Fields
    module CustomerRisk
      # Q1 — aACTIVE: Have you acted as professional agent for purchases/sales
      # or rentals during the reporting period?
      # Type: enum "Oui" / "Non"
      def aactive
        organization.transactions.kept.for_year(year).exists? ? "Oui" : "Non"
      end

      # Q2 — aACTIVEPS: Active for purchases/sales during the reporting period?
      # Type: enum "Oui" / "Non"
      def aactiveps
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE]).exists? ? "Oui" : "Non"
      end

      # Q3 — aACTIVERENTALS: Active for rentals (monthly rent >= 10,000 EUR) during reporting period?
      # Type: enum "Oui" / "Non"
      def aactiverentals
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .exists? ? "Oui" : "Non"
      end

      # Q4 — a1101: Total unique clients active during reporting period
      # Counts unique clients with purchase/sale transactions OR
      # rental transactions with monthly rent >= 10,000 EUR (annual >= 120,000)
      # Type: xbrli:integerItemType
      def a1101
        txns = organization.transactions.kept.for_year(year)

        purchase_sale_client_ids = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .pluck(:client_id)

        rental_client_ids = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .pluck(:client_id)

        (purchase_sale_client_ids + rental_client_ids).uniq.count
      end

      # Q5 — a1105B: Total number of transactions during reporting period
      # for purchase, sale, and rental (monthly rent >= 10,000 EUR) of real estate
      # Type: xbrli:integerItemType
      def a1105b
        txns = organization.transactions.kept.for_year(year)

        purchase_sale_count = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .count

        rental_count = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .count

        purchase_sale_count + rental_count
      end

      # Q6 — a1106B: Total value of funds transferred for purchase and sale of real estate
      # Type: xbrli:monetaryItemType
      def a1106b
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .sum(:transaction_value)
      end

      # Q7 — a1106BRENTALS: Total value of funds transferred for rental of real estate
      # Type: xbrli:monetaryItemType
      def a1106brentals
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "RENTAL")
          .sum(:transaction_value)
      end

      # Q9 — a1106W: Total value of funds transferred with clients during reporting period
      # for purchase, sale, and rental (monthly rent >= 10,000 EUR) of real estate
      # Type: xbrli:monetaryItemType
      def a1106w
        txns = organization.transactions.kept.for_year(year)

        ps_value = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .sum(:transaction_value)

        rental_value = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .sum(:transaction_value)

        ps_value + rental_value
      end

      # Q8 — a1105W: Total number of transactions with clients during reporting period
      # for purchase, sale, and rental (monthly rent >= 10,000 EUR) of real estate
      # Type: xbrli:integerItemType
      def a1105w
        txns = organization.transactions.kept.for_year(year)

        purchase_sale_count = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .count

        rental_count = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .count

        purchase_sale_count + rental_count
      end

      # Q10 — a1204S: Can your entity distinguish the nationality of the beneficial owner of clients?
      # Type: enum "Oui" / "Non" (settings-based)
      def a1204s
        setting_value_for("can_distinguish_bo_nationality")
      end

      # Q11 — a1204S1: Percentage breakdown of beneficial owners' primary nationalities
      # Type: xbrli:pureItemType (percentage, max 100) — dimensional by country
      # Includes all BOs (all ownership levels, direct/indirect control, representatives)
      def a1204s1
        return nil if a1204s == "Non"

        bos = BeneficialOwner
          .joins(:client)
          .where(clients: {organization_id: organization.id})
          .where.not(nationality: nil)

        total = bos.count
        return {} if total == 0

        counts = bos.group(:nationality).count
        counts.transform_values { |count| (BigDecimal(count) / total * 100).round(2) }
      end
    end
  end
end
