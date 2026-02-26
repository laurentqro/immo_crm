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
    end
  end
end
