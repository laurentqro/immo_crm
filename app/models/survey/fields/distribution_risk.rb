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
      # Type: xbrli:integerItemType — dimensional by country
      def a3102
        country_sql = client_country_sql

        clients_kept
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
      # Type: xbrli:integerItemType — dimensional by country
      def a3104
        country_sql = client_country_sql

        clients_kept
          .where(third_party_cdd: true, third_party_cdd_type: "FOREIGN")
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q172 — a3105: Clients with foreign third-party CDD, by third-party country (dimensional)
      # Type: xbrli:integerItemType — dimensional by country
      def a3105
        clients_kept
          .where(third_party_cdd: true, third_party_cdd_type: "FOREIGN")
          .where.not(third_party_cdd_country: nil)
          .group(:third_party_cdd_country)
          .count
      end

      # Q173 — aB3206: New NP clients onboarded during reporting period
      # Type: xbrli:integerItemType — computed
      def ab3206
        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        clients_kept
          .where(client_type: "NATURAL_PERSON")
          .where(became_client_at: year_range)
          .count
      end

      # Q174 — aB3207: New legal entity clients (excl. trusts) onboarded during reporting period
      # Type: xbrli:integerItemType — computed
      def ab3207
        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        clients_kept
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

        clients_kept
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
      # Type: xbrli:integerItemType — computed, conditional on a3209
      def a3210c
        return nil unless a3209 == "Oui"

        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        clients_kept
          .where(client_type: "NATURAL_PERSON", non_face_to_face_onboarding: true)
          .where(became_client_at: year_range)
          .count
      end

      # Q178 — a3211C: LE clients onboarded without face-to-face during reporting period
      # Type: xbrli:integerItemType — DB-computed, conditional on a3209
      def a3211c
        return nil unless a3209 == "Oui"

        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        clients_kept
          .where(client_type: "LEGAL_ENTITY", non_face_to_face_onboarding: true)
          .where(became_client_at: year_range)
          .count
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

        country_sql = client_country_sql

        clients_kept
          .where(introduced_by_third_party: true)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q183 — a3204: Introduced clients in reporting period by primary nationality (dimensional)
      # Type: xbrli:integerItemType — computed, dimensional by country
      def a3204
        country_sql = client_country_sql

        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        clients_kept
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

        clients_kept
          .where(introduced_by_third_party: true)
          .where.not(introducer_country: nil)
          .group(:introducer_country)
          .count
      end

      # Q186 — a3205: Introduced clients in reporting period by introducer residence (dimensional)
      # Type: xbrli:integerItemType — computed, dimensional by country
      def a3205
        year_range = Date.new(year, 1, 1)..Date.new(year, 12, 31)

        clients_kept
          .where(introduced_by_third_party: true)
          .where(became_client_at: year_range)
          .where.not(introducer_country: nil)
          .group(:introducer_country)
          .count
      end

      LEGAL_FORM_XBRL_LABELS = {
        "AM" => "01. Associations monégasques",
        "ASC" => "02. Autres sociétés civiles",
        "AAJ" => "04. Autres arrangements juridiques",
        "DPE" => "05. Domaine Privé de l'Etat Monégasque",
        "EI" => "06. Entreprise individuelle",
        "FM" => "07. Fondation monégasque",
        "GIE" => "08. Groupement d'Intérêt économiques",
        "SNC" => "09. Sociétés en nom collectif",
        "SCI" => "10. Sociétés civiles immobilières",
        "SCP" => "11. Sociétés civiles particulières",
        "SCS" => "12. Sociétés en commandite simple",
        "SARL" => "13. Sociétés à responsabilité limitée",
        "SAM" => "14. Sociétés anonymes monégasques",
        "SCA" => "15. Sociétés en commandite par actions",
        "TRUST" => "16. Trusts",
        "INCONNU" => "17. Inconnu (LE)"
      }.freeze

      # Q187 — aIR33LF: Legal form of entity
      # Type: enum (various legal forms) — settings-based
      def air33lf
        code = setting_value_for("entity_legal_form")
        LEGAL_FORM_XBRL_LABELS[code]
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

      # Q195 — a3306: Foreign branches by country (dimensional, outside Monaco)
      # Type: xbrli:integerItemType — computed from DB, dimensional by country
      def a3306
        organization.branches.foreign.group(:country).count
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

      # Q206 — a3803: Revenue outside Monaco
      # Type: xbrli:monetaryItemType (iso4217:EUR) — settings-based
      def a3803
        setting_value_for("revenue_outside_monaco")
      end

      # Q207 — a3804: Annual VAT declaration amount
      # Type: xbrli:monetaryItemType (iso4217:EUR) — settings-based
      def a3804
        setting_value_for("annual_vat_declaration_amount")
      end

      # Q208 — a3401: Total rejected prospects due to AML/CFT considerations
      # Type: xbrli:integerItemType — settings-based
      def a3401
        setting_value_for("rejected_prospects_count")
      end

      # Q209 — a3402: Can entity distinguish rejection reasons?
      # Type: enum (Oui/Non) — settings-based
      def a3402
        setting_value_for("can_distinguish_rejection_reasons")
      end

      # Q210 — a3403: Rejected prospects due to client attributes/activities/deficiencies
      # Type: xbrli:integerItemType — settings-based, conditional on a3402
      def a3403
        return nil unless a3402 == "Oui"
        setting_value_for("rejected_prospects_client_attribute_count")
      end

      # Q211 — a3414: Total terminated client relationships due to AML/CFT considerations
      # Type: xbrli:integerItemType — settings-based
      def a3414
        setting_value_for("terminated_relationships_count")
      end

      # Q212 — a3415: Can entity distinguish termination reasons?
      # Type: enum (Oui/Non) — settings-based
      def a3415
        setting_value_for("can_distinguish_termination_reasons")
      end

      # Q213 — a3416: Terminated relationships due to client attributes/activities/deficiencies
      # Type: xbrli:integerItemType — settings-based, conditional on a3415
      def a3416
        return nil unless a3415 == "Oui"
        setting_value_for("terminated_relationships_client_attribute_count")
      end

      # Q214 — a3701A: Has comments on distribution risk section?
      # Type: enum (Oui/Non)
      def a3701a
      end

      # Q215 — a3701: Distribution risk section comments
      # Type: xbrli:stringItemType
      def a3701
      end
    end
  end
end
