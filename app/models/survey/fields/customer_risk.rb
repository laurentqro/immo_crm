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
    end
  end
end
