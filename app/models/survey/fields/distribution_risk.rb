# frozen_string_literal: true

# Tab 3: Distribution Channel Risk Assessment
# Field methods for distribution channel risk metrics
#
# Fields cover:
# - Third-party CDD (Customer Due Diligence)
# - Client introduction channels
# - Non-face-to-face relationships
# - Geographic distribution
#
class Survey
  module Fields
    module DistributionRisk
      extend ActiveSupport::Concern
      include Helpers

      private

      # === Third-Party CDD ===

      # Q: Do you use third-party CDD from local providers?
      def a3101
        clients_kept.with_local_third_party_cdd.exists? ? "Oui" : "Non"
      end

      # Q: Do you use third-party CDD from foreign providers?
      def a3103
        clients_kept.with_foreign_third_party_cdd.exists? ? "Oui" : "Non"
      end

      def ac1622f
        (a3101 == "Oui" || a3103 == "Oui") ? "Oui" : "Non"
      end

      def ac1622a
        setting_value("ac1622a") || "Non"
      end

      def ac1622b
        setting_value("ac1622b")
      end

      # Clients where local third parties performed CDD, grouped by client nationality
      def a3102
        clients_kept
          .with_local_third_party_cdd
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Clients where foreign third parties performed CDD, grouped by client nationality
      def a3104
        clients_kept
          .with_foreign_third_party_cdd
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Clients where foreign third parties performed CDD, grouped by third-party's country
      def a3105
        clients_kept
          .with_foreign_third_party_cdd
          .where.not(third_party_cdd_country: [nil, ""])
          .group(:third_party_cdd_country)
          .count
      end

      # === Client Introduction Channels ===

      # Q180: Do you accept clients through introducers?
      def a3201
        clients_kept.introduced.exists? ? "Oui" : "Non"
      end

      # Q182: Total introduced clients grouped by client nationality
      def a3202
        clients_kept
          .introduced
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Q183: Clients introduced this year, grouped by client nationality
      def a3204
        clients_kept
          .introduced
          .where(became_client_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Q185: Total introduced clients grouped by introducer country
      def a3203
        clients_kept
          .introduced
          .where.not(introducer_country: [nil, ""])
          .group(:introducer_country)
          .count
      end

      # Q186: Clients introduced this year, grouped by introducer country
      def a3205
        clients_kept
          .introduced
          .where(became_client_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
          .where.not(introducer_country: [nil, ""])
          .group(:introducer_country)
          .count
      end

      # === New Clients by Type ===

      # Q173: New unique natural person clients in the reporting period
      def ab3206
        clients_kept
          .natural_persons
          .where(became_client_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
          .count
      end

      # Q174: New unique legal entity clients (excluding trusts) in the reporting period
      def ab3207
        clients_kept
          .legal_entities
          .where.not(legal_entity_type: "TRUST")
          .where(became_client_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
          .count
      end

      # Q175: New unique trust/legal construction clients in the reporting period
      def a3208tola
        clients_kept
          .trusts
          .where(became_client_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
          .count
      end

      # === Non-Face-to-Face Relationships ===

      def a3209
        setting_value("a3209") || "Non"
      end

      def a3210c
        0
      end

      def a3211c
        0
      end

      def a3212ctola
        0
      end

      # Non-face-to-face for legal entities
      def a3210b
        setting_value("a3210b") || "Non"
      end

      def a3211b
        setting_value("a3211b")
      end

      # Non-face-to-face by nationality
      def a3210
        setting_value("a3210") || "Non"
      end

      def a3211
        setting_value("a3211")
      end

      # === Risk Assessment ===

      # Q181: Can you provide client nationality for introduced clients?
      def a3501b
        "Oui"
      end

      # Q184: Can you provide introducer country/residency?
      def a3501c
        "Oui"
      end

      # === Acquisition and Marketing Channels ===

      def ac1608
        setting_value("ac1608") || "Non"
      end

      def ac1631
        setting_value("ac1631") || "Non"
      end

      def ac1633
        setting_value("ac1633") || "Non"
      end

      def ac1634
        setting_value("ac1634") || "Non"
      end

      def ac1630
        setting_value("ac1630")
      end

      # === Geographic Scope ===

      def ac1602
        setting_value("ac1602")
      end
    end
  end
end
