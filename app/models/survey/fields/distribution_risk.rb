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

      # Q177 — a3210C: NP clients onboarded without face-to-face during reporting period
      # Type: xbrli:integerItemType — settings-based, conditional on a3209
      def a3210c
        return nil unless a3209 == "Oui"
        setting_value_for("non_face_to_face_np_onboarded_count")
      end

      # Q178 — a3211C: LP clients onboarded without face-to-face during reporting period
      # Type: xbrli:integerItemType — settings-based, conditional on a3209
      def a3211c
        return nil unless a3209 == "Oui"
        setting_value_for("non_face_to_face_lp_onboarded_count")
      end

      # Q179 — a3212CTOLA: Trust clients onboarded without face-to-face during reporting period
      # Type: xbrli:integerItemType — settings-based, conditional on a3209 AND a1802btola
      def a3212ctola
        return nil unless a3209 == "Oui"
        return nil unless a1802btola == "Oui"
        setting_value_for("non_face_to_face_trust_onboarded_count")
      end

      # Q180 — a3201: Entity accepts clients through introducers
      # Type: enum (Oui/Non) — settings-based
      def a3201
        setting_value_for("accepts_clients_through_introducers")
      end

      # Q181 — a3501B: Can entity provide nationality info for introduced clients?
      # Type: enum (Oui/Non) — settings-based, conditional on a3201
      def a3501b
        return nil unless a3201 == "Oui"
        setting_value_for("can_provide_introducer_client_nationality")
      end

      # Q182 — a3202: Introduced clients by primary nationality (dimensional)
      # Type: xbrli:integerItemType — computed, dimensional by country, conditional on a3501B
      def a3202
        return nil unless a3501b == "Oui"

        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        organization.clients.kept
          .where(introduced_by_third_party: true)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q183 — a3204: Introduced clients in reporting period by primary nationality (dimensional)
      # Type: xbrli:integerItemType — computed, dimensional by country, conditional on a3501B
      def a3204
        return nil unless a3501b == "Oui"

        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        organization.clients.kept
          .where(introduced_by_third_party: true)
          .where(became_client_at: year_range)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q184 — a3501C: Can entity provide residence info for introducers?
      # Type: enum (Oui/Non) — settings-based, conditional on a3201
      def a3501c
        return nil unless a3201 == "Oui"
        setting_value_for("can_provide_introducer_residence")
      end

      # Q185 — a3203: Introduced clients by introducer residence (dimensional)
      # Type: xbrli:integerItemType — computed, dimensional by country, conditional on a3501C
      def a3203
        return nil unless a3501c == "Oui"

        organization.clients.kept
          .where(introduced_by_third_party: true)
          .where.not(introducer_country: nil)
          .group(:introducer_country)
          .count
      end

      # Q186 — a3205: Introduced clients in reporting period by introducer residence (dimensional)
      # Type: xbrli:integerItemType — computed, dimensional by country, conditional on a3501C
      def a3205
        return nil unless a3501c == "Oui"

        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        organization.clients.kept
          .where(introduced_by_third_party: true)
          .where(became_client_at: year_range)
          .where.not(introducer_country: nil)
          .group(:introducer_country)
          .count
      end

      # Q187 — aIR33LF: Legal form of entity
      # Type: enum (various legal forms) — settings-based
      def air33lf
        setting_value_for("entity_legal_form")
      end

      # Q188 — aIR328: Is professional card holder a legal entity?
      # Type: enum (Oui/Non) — settings-based
      def air328
        setting_value_for("card_holder_is_legal_entity")
      end

      # Q189 — a3301: Total employee headcount at end of reporting period
      # Type: xbrli:integerItemType — settings-based
      def a3301
        setting_value_for("total_employee_headcount")
      end

      # Q190 — a3302: Does entity have branches, subsidiaries, or agencies?
      # Type: enum (Oui/Non) — settings-based
      def a3302
        setting_value_for("has_branches")
      end

      # Q191 — a3303: Total branches by country (dimensional)
      # Type: xbrli:integerItemType — settings-based dimensional, conditional on a3302
      def a3303
        return nil unless a3302 == "Oui"

        json = setting_value_for("branches_by_country")
        return nil if json.nil?

        JSON.parse(json)
      end

      # Q192 — a3304: Is entity a branch or subsidiary of a foreign entity?
      # Type: enum (Oui/Non) — settings-based, conditional on a3304C
      def a3304
        return nil unless a3304c == "Oui"
        setting_value_for("is_branch_of_foreign_entity")
      end

      # Q193 — a3304C: Is entity a branch or subsidiary of another entity?
      # Type: enum (Oui/Non) — settings-based
      def a3304c
        setting_value_for("is_branch_of_another_entity")
      end

      # Q194 — a3305: Parent company country
      # Type: enum (country names) — settings-based, conditional on a3304
      def a3305
        return nil unless a3304 == "Oui"
        setting_value_for("parent_company_country")
      end

      # Q195 — a3306: Total foreign branches count (outside Monaco)
      # Type: xbrli:integerItemType — settings-based, conditional on a3304
      def a3306
        return nil unless a3304 == "Oui"
        setting_value_for("total_foreign_branches")
      end

      # Q196 — a3306A: Shareholders with 25%+ by nationality (dimensional)
      # Type: xbrli:integerItemType (maxInclusive=4) — settings-based dimensional, conditional on aIR328
      def a3306a
        return nil unless air328 == "Oui"

        json = setting_value_for("shareholders_25pct_by_nationality")
        return nil if json.nil?

        JSON.parse(json)
      end

      # Q197 — a3306B: BOs with 25%+ by nationality (dimensional)
      # Type: xbrli:integerItemType — settings-based dimensional, conditional on aIR328
      def a3306b
        return nil unless air328 == "Oui"

        json = setting_value_for("bos_25pct_by_nationality")
        return nil if json.nil?

        JSON.parse(json)
      end

      # Q198 — a3307: Changes in structure during reporting period?
      # Type: enum (Oui/Non) — settings-based
      def a3307
        setting_value_for("structural_changes_during_period")
      end

      # Q199 — a3308: Describe structural changes
      # Type: xbrli:stringItemType — settings-based, conditional on a3307
      def a3308
        return nil unless a3307 == "Oui"
        setting_value_for("structural_changes_description")
      end

      # Q200 — a3210B: Part of international business network?
      # Type: enum (Oui/Non) — settings-based
      def a3210b
        setting_value_for("part_of_international_network")
      end

      # Q201 — a3211B: Specify international network
      # Type: xbrli:stringItemType — settings-based, conditional on a3210B
      def a3211b
        return nil unless a3210b == "Oui"
        setting_value_for("international_network_name")
      end

      # Q202 — a3210: Member of professional association?
      # Type: enum (Oui/Non) — settings-based
      def a3210
        setting_value_for("member_of_professional_association")
      end

      # Q203 — a3211: Specify professional association
      # Type: xbrli:stringItemType — settings-based, conditional on a3210
      def a3211
        return nil unless a3210 == "Oui"
        setting_value_for("professional_association_name")
      end

      # Q204 — a381: Revenue for reporting period
      # Type: xbrli:monetaryItemType (iso4217:EUR) — settings-based
      def a381
        setting_value_for("revenue_reporting_period")
      end

      # Q205 — a3802: Revenue in Monaco
      # Type: xbrli:monetaryItemType (iso4217:EUR) — settings-based
      def a3802
        setting_value_for("revenue_in_monaco")
      end
    end
  end
end
