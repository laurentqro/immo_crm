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
    end
  end
end
