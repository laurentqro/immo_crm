# frozen_string_literal: true

class Survey
  module Fields
    module DistributionRisk
      # Q168 — a3101: Does entity use local third parties for CDD?
      # Type: enum (Oui/Non) — settings-based
      def a3101
        setting_value_for("uses_local_third_party_cdd")
      end

      # Q169 — a3102: Clients with local third-party CDD, by primary nationality (dimensional)
      # Type: xbrli:integerItemType — dimensional by country, conditional on a3101
      def a3102
        return nil unless a3101 == "Oui"

        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        organization.clients.kept
          .where(third_party_cdd: true, third_party_cdd_type: "LOCAL")
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q170 — a3103: Does entity use foreign third parties for CDD?
      # Type: enum (Oui/Non) — settings-based
      def a3103
        setting_value_for("uses_foreign_third_party_cdd")
      end

      # Q171 — a3104: Clients with foreign third-party CDD, by primary nationality (dimensional)
      # Type: xbrli:integerItemType — dimensional by country, conditional on a3103
      def a3104
        return nil unless a3103 == "Oui"

        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        organization.clients.kept
          .where(third_party_cdd: true, third_party_cdd_type: "FOREIGN")
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q172 — a3105: Clients with foreign third-party CDD, by third-party country (dimensional)
      # Type: xbrli:integerItemType — dimensional by country, conditional on a3103
      def a3105
        return nil unless a3103 == "Oui"

        organization.clients.kept
          .where(third_party_cdd: true, third_party_cdd_type: "FOREIGN")
          .where.not(third_party_cdd_country: nil)
          .group(:third_party_cdd_country)
          .count
      end

      # Q173 — aB3206: New NP clients onboarded during reporting period
      # Type: xbrli:integerItemType — computed
      def ab3206
        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        organization.clients.kept
          .where(client_type: "NATURAL_PERSON")
          .where(became_client_at: year_range)
          .count
      end

      # Q174 — aB3207: New legal entity clients (excl. trusts) onboarded during reporting period
      # Type: xbrli:integerItemType — computed
      def ab3207
        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        organization.clients.kept
          .where(client_type: "LEGAL_ENTITY")
          .where.not(legal_entity_type: "TRUST")
          .where(became_client_at: year_range)
          .count
      end

      # Q175 — a3208TOLA: New trust/legal construction clients onboarded during reporting period
      # Type: xbrli:integerItemType — computed, conditional on a1802btola
      def a3208tola
        return nil unless a1802btola == "Oui"

        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        organization.clients.kept
          .where(client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST")
          .where(became_client_at: year_range)
          .count
      end

      # Q176 — a3209: Does entity onboard clients without face-to-face?
      # Type: enum (Oui/Non) — settings-based
      def a3209
        setting_value_for("non_face_to_face_onboarding")
      end
    end
  end
end
