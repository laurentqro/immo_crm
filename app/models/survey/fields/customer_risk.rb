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

      # Q12 — a1202O: Total number of BOs exercising direct or indirect control
      # over legal persons, trusts and other legal arrangements, by primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      def a1202o
        bos = BeneficialOwner
          .joins(:client)
          .where(clients: {organization_id: organization.id})
          .where(control_type: %w[DIRECT INDIRECT])
          .where.not(nationality: nil)

        bos.group(:nationality).count
      end

      # Q13 — a1202OB: Total number of BOs representing a legal person,
      # broken down by primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      def a1202ob
        bos = BeneficialOwner
          .joins(:client)
          .where(clients: {organization_id: organization.id})
          .where(control_type: "REPRESENTATIVE")
          .where.not(nationality: nil)

        bos.group(:nationality).count
      end

      # Q14 — a1204O: Can entity distinguish beneficial owners that hold 25% or more?
      # Type: enum (Oui/Non) — settings-based
      def a1204o
        setting_value_for("can_distinguish_bo_25pct_or_more")
      end

      # Q15 — a120425O: Total number of BOs holding at least 25%,
      # broken down by primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a1204o == "Oui"
      def a120425o
        return nil unless a1204o == "Oui"

        BeneficialOwner
          .joins(:client)
          .where(clients: {organization_id: organization.id})
          .with_significant_control
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q16 — a1203D: Does entity record residence for BOs holding 25% or more?
      # Type: enum (Oui/Non) — settings-based
      def a1203d
        setting_value_for("records_bo_residence_25pct_or_more")
      end

      # Q17 — a1207O: Total number of BOs who are foreign residents (residence != MC),
      # holding 25% or more, broken down by primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a1203d == "Oui"
      def a1207o
        return nil unless a1203d == "Oui"

        BeneficialOwner
          .joins(:client)
          .where(clients: {organization_id: organization.id})
          .with_significant_control
          .where.not(residence_country: "MC")
          .where.not(residence_country: nil)
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q18 — a1210O: Total number of BOs who are non-residents (no residence recorded),
      # holding 25% or more, broken down by primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a1203d == "Oui"
      def a1210o
        return nil unless a1203d == "Oui"

        BeneficialOwner
          .joins(:client)
          .where(clients: {organization_id: organization.id})
          .with_significant_control
          .where(residence_country: nil)
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q19 — a11201BCD: Does entity identify and record client type: HNWIs?
      # Type: enum "Oui" / "Non" (settings-based)
      def a11201bcd
        setting_value_for("identifies_records_hnwi_clients")
      end

      # Q20 — a11201BCDU: Does entity identify and record client type: UHNWIs?
      # Type: enum "Oui" / "Non" (settings-based)
      def a11201bcdu
        setting_value_for("identifies_records_uhnwi_clients")
      end

      # Q21 — a1801: Does entity identify/record trusts and other legal constructions?
      # Type: enum "Oui" / "Non" (settings-based)
      def a1801
        setting_value_for("identifies_records_trusts_legal_constructions")
      end

      # Q22 — a13601: Does entity have PSAV clients that provide other services?
      # Type: enum "Oui" / "Non" (settings-based)
      def a13601
        setting_value_for("has_psav_clients_other_services")
      end

      # Q23 — a1102: Total unique natural person clients who are nationals (MC nationality)
      # for purchases, sales, and rentals (>= 10k/month) of real estate
      # Type: xbrli:integerItemType
      def a1102
        txns = organization.transactions.kept.for_year(year)

        purchase_sale_client_ids = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON", nationality: "MC"})
          .pluck(:client_id)

        rental_client_ids = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON", nationality: "MC"})
          .pluck(:client_id)

        (purchase_sale_client_ids + rental_client_ids).uniq.count
      end

      # Q24 — a1103: Total unique natural person clients who are foreign residents
      # for purchases, sales, and rentals (>= 10k/month) of real estate
      # Type: xbrli:integerItemType
      def a1103
        txns = organization.transactions.kept.for_year(year)

        purchase_sale_client_ids = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .where.not(clients: {residence_country: [nil, "MC"]})
          .pluck(:client_id)

        rental_client_ids = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .where.not(clients: {residence_country: [nil, "MC"]})
          .pluck(:client_id)

        (purchase_sale_client_ids + rental_client_ids).uniq.count
      end

      # Q25 — a1104: Total unique natural person clients who are non-residents
      # (nil residence_country) for purchases, sales, and rentals (>= 10k/month) of real estate
      # Type: xbrli:integerItemType
      def a1104
        txns = organization.transactions.kept.for_year(year)

        purchase_sale_client_ids = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON", residence_country: nil})
          .pluck(:client_id)

        rental_client_ids = txns
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON", residence_country: nil})
          .pluck(:client_id)

        (purchase_sale_client_ids + rental_client_ids).uniq.count
      end

      # Q26 — a1401: Total unique natural person clients by primary nationality
      # for purchase and sale of real estate
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      def a1401
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .where.not(clients: {nationality: nil})
          .distinct
          .group("clients.nationality")
          .count("clients.id")
      end

      # Q29 — a1401R: Total unique natural person clients
      # for rental of real estate (monthly rent >= 10,000 EUR)
      # Type: xbrli:integerItemType (scalar — NoCountryDimension)
      def a1401r
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .distinct
          .count("clients.id")
      end

      # Q30 — a1403R: Total transactions by natural person clients
      # for rental of real estate (monthly rent >= 10,000 EUR)
      # Type: xbrli:integerItemType (scalar — NoCountryDimension)
      def a1403r
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .count
      end

      # Q27 — a1403B: Total transactions by natural person clients for purchase/sale
      # Type: xbrli:integerItemType — scalar integer (no country dimension)
      def a1403b
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .count
      end

      # Q28 — a1404B: Total value of funds transferred by NP clients for purchase/sale
      # Type: xbrli:monetaryItemType (EUR)
      def a1404b
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .sum(:transaction_value)
      end

      # Q31 — aIR129: Were some real estate purchases during the reporting period
      # intended to establish a residence in Monaco?
      # Type: enum "Oui" / "Non" (settings-based)
      def air129
        setting_value_for("purchases_intended_for_residence_establishment")
      end

      # Q32 — aIR1210: How many purchases have been made for the purpose of
      # establishing a residence in Monaco during the reporting period?
      # Type: xbrli:integerItemType (conditional on air129)
      def air1210
        return nil unless air129 == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: "PURCHASE", purchase_purpose: "RESIDENCE")
          .count
      end

      # Q33 — a1501: Total unique legal entity clients (excl. trusts)
      # by incorporation country, for purchase and sale of real estate
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      def a1501
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {legal_entity_type: "TRUST"})
          .where.not(clients: {incorporation_country: nil})
          .distinct
          .group("clients.incorporation_country")
          .count("clients.id")
      end

      # Q34 — a1502B: Total transactions by legal entity clients (excl. trusts)
      # for purchase and sale of real estate
      # Type: xbrli:integerItemType
      def a1502b
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {legal_entity_type: "TRUST"})
          .count
      end

      # Q35 — a1503B: Total value of funds transferred by legal entity clients
      # (excl. trusts) for purchase and sale of real estate
      # Type: xbrli:monetaryItemType (EUR)
      def a1503b
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {legal_entity_type: "TRUST"})
          .sum(:transaction_value)
      end

      # Q36 — a155: Does your entity distinguish if clients are Monegasque legal entities
      # and the type of legal entity?
      # Type: stringItemType with enum restriction ("Oui" / "Non") — settings-based
      def a155
        setting_value_for("can_distinguish_monegasque_legal_entity_type")
      end

      # Q37 — aMLES: Number of Monegasque legal entity clients, broken down by type
      # Type: xbrli:integerItemType — dimensional by legal_entity_type
      # Scope: Purchase/Sale, incorporation_country == "MC", excludes trusts
      # Conditional: only when a155 == "Oui"
      def amles
        return nil unless a155 == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", incorporation_country: "MC"})
          .where.not(clients: {legal_entity_type: "TRUST"})
          .where.not(clients: {legal_entity_type: nil})
          .distinct
          .group("clients.legal_entity_type")
          .count("clients.id")
      end

      # Q38 — a11206B: Total unique HNWI beneficial owners of legal entity clients,
      # broken down by primary nationality of the HNWI
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Scope: Purchase/Sale only, legal entity clients (excl. trusts)
      # Conditional: only when a11201bcd == "Oui"
      def a11206b
        return nil unless a11201bcd == "Oui"

        legal_entity_client_ids = organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {legal_entity_type: "TRUST"})
          .select("clients.id")
          .distinct

        BeneficialOwner
          .where(client_id: legal_entity_client_ids)
          .merge(BeneficialOwner.hnwis)
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q39 — a112012B: Total unique UHNWI beneficial owners of legal entity clients,
      # broken down by primary nationality of the UHNWI
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Scope: Purchase/Sale only, legal entity clients (excl. trusts)
      # Conditional: only when a11201bcdu == "Oui"
      def a112012b
        return nil unless a11201bcdu == "Oui"

        legal_entity_client_ids = organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {legal_entity_type: "TRUST"})
          .select("clients.id")
          .distinct

        BeneficialOwner
          .where(client_id: legal_entity_client_ids)
          .merge(BeneficialOwner.uhnwis)
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q40 — a1802BTOLA: Does entity distinguish if clients are trusts or other legal constructions?
      # Type: stringItemType with enum restriction ("Oui" / "Non") — settings-based
      def a1802btola
        setting_value_for("can_distinguish_trust_clients")
      end

      # Q41 — a1802TOLA: Total unique trust/legal construction clients
      # for purchases, sales, and rentals of real estate
      # Type: xbrli:integerItemType (scalar — NoCountryDimension)
      # Conditional: only when a1802btola == "Oui"
      def a1802tola
        return nil unless a1802btola == "Oui"

        txns = organization.transactions.kept.for_year(year)

        purchase_sale_client_ids = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST"})
          .pluck(:client_id)

        rental_client_ids = txns
          .where(transaction_type: "RENTAL")
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST"})
          .pluck(:client_id)

        (purchase_sale_client_ids + rental_client_ids).uniq.count
      end

      # Q42 — a1807ATOLA: Total unique Monegasque trust/legal construction clients
      # for purchases, sales, and rentals of real estate
      # Type: xbrli:integerItemType — conditional on a1802btola == "Oui"
      def a1807atola
        return nil unless a1802btola == "Oui"

        txns = organization.transactions.kept.for_year(year)

        purchase_sale_client_ids = txns
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", incorporation_country: "MC"})
          .pluck(:client_id)

        rental_client_ids = txns
          .where(transaction_type: "RENTAL")
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", incorporation_country: "MC"})
          .pluck(:client_id)

        (purchase_sale_client_ids + rental_client_ids).uniq.count
      end

      # Q43 — a1808: Total professional trustees (natural persons),
      # broken down by primary nationality, for purchase, sale and rental
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a1802btola == "Oui"
      def a1808
        return nil unless a1802btola == "Oui"

        trust_client_ids = organization.transactions.kept.for_year(year)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST"})
          .select(:client_id)
          .distinct

        Trustee
          .where(client_id: trust_client_ids)
          .where(is_professional: true)
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q44 — a1809: Professional trustees (natural persons),
      # broken down by country in which the trust was created,
      # for purchase, sale and rental
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a1802btola == "Oui"
      def a1809
        return nil unless a1802btola == "Oui"

        trust_client_ids = organization.transactions.kept.for_year(year)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST"})
          .select(:client_id)
          .distinct

        Trustee
          .joins(:client)
          .where(client_id: trust_client_ids)
          .where(is_professional: true)
          .where.not(clients: {incorporation_country: nil})
          .group("clients.incorporation_country")
          .count
      end

      # Q45 — a11001BTOLA: Does entity have information on the number and value
      # of trust/legal construction clients' transactions?
      # Type: stringItemType enum ("Oui" / "Non")
      # Conditional: only present when a1802btola == "Oui"
      def a11001btola
        return nil unless a1802btola == "Oui"
        setting_value_for("trust_clients_transaction_info_available")
      end

      # Q46 — a1806TOLA: Total number of transactions by trust/legal construction clients
      # for purchase and sale of real estate
      # Type: xbrli:integerItemType
      # Conditional: only when a11001btola == "Oui"
      def a1806tola
        return nil unless a11001btola == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST"})
          .count
      end

      # Q47 — a1807TOLA: Total value of funds transferred by trust/legal construction clients
      # for purchase and sale of real estate
      # Type: xbrli:monetaryItemType (EUR)
      # Conditional: only when a11001btola == "Oui"
      def a1807tola
        return nil unless a11001btola == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST"})
          .sum(:transaction_value)
      end

      # Q48 — a11006: Specify type of other legal constructions not mentioned in previous questions
      # Type: xbrli:stringItemType
      # Conditional: only when a1802btola == "Oui"
      # Collects non-standard legal entity type labels (excluding AMSF_STANDARD_LEGAL_FORMS)
      # For "OTHER" type, uses the free-text legal_entity_type_other field
      def a11006
        return nil unless a1802btola == "Oui"

        other_clients = organization.clients.kept
          .where(client_type: "LEGAL_ENTITY")
          .where.not(legal_entity_type: AmsfConstants::AMSF_STANDARD_LEGAL_FORMS)
          .where.not(legal_entity_type: nil)

        types = other_clients.distinct.pluck(:legal_entity_type, :legal_entity_type_other)
        return nil if types.empty?

        labels = types.map do |type, other_text|
          if type == "OTHER" && other_text.present?
            other_text
          else
            AmsfConstants::LEGAL_ENTITY_TYPE_LABELS[type] || type
          end
        end

        labels.uniq.sort.join(", ")
      end

      # === Section 1.8: PEPs ===

      # Q49 — a11301: Does entity have PEP clients?
      # Type: enum "Oui" / "Non" (computed)
      # Checks if any PEP client had transactions during the reporting year
      def a11301
        pep_client_ids = organization.clients.kept.peps.pluck(:id)
        return "Non" if pep_client_ids.empty?

        has_transactions = organization.transactions.kept.for_year(year)
          .where(client_id: pep_client_ids)
          .exists?

        has_transactions ? "Oui" : "Non"
      end

      # Q50 — a11302RES: Total unique PEP clients by residence country
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Scope: Purchases, sales, and rentals
      # Conditional: only when a11301 == "Oui"
      def a11302res
        return nil unless a11301 == "Oui"

        pep_client_ids = organization.clients.kept.peps.pluck(:id)

        txn_scope = organization.transactions.kept.for_year(year)
          .where(client_id: pep_client_ids)

        purchase_sale_clients = txn_scope
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .select("clients.id, clients.residence_country")

        rental_clients = txn_scope
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .select("clients.id, clients.residence_country")

        all_rows = purchase_sale_clients + rental_clients
        grouped = all_rows
          .map { |r| [r.id, r.residence_country] }
          .uniq
          .group_by(&:last)
          .transform_values(&:count)

        grouped.delete(nil)
        grouped
      end

      # Q51 — a11302: Total unique PEP clients by primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Scope: Purchases, sales, and rentals
      # Conditional: only when a11301 == "Oui"
      def a11302
        return nil unless a11301 == "Oui"

        pep_client_ids = organization.clients.kept.peps.pluck(:id)

        txn_scope = organization.transactions.kept.for_year(year)
          .where(client_id: pep_client_ids)

        purchase_sale_clients = txn_scope
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .select("clients.id, clients.nationality")

        rental_clients = txn_scope
          .where(transaction_type: "RENTAL")
          .where(Transaction.arel_table[:rental_annual_value].gteq(120_000))
          .joins(:client)
          .select("clients.id, clients.nationality")

        all_rows = purchase_sale_clients + rental_clients
        grouped = all_rows
          .map { |r| [r.id, r.nationality] }
          .uniq
          .group_by(&:last)
          .transform_values(&:count)

        grouped.delete(nil)
        grouped
      end

      # Q52 — a11304B: Total transactions by PEP clients for purchase/sale
      # Type: xbrli:integerItemType
      # Scope: Purchase and sale transactions only (NOT rentals)
      # Conditional: only when a11301 == "Oui"
      def a11304b
        return nil unless a11301 == "Oui"

        pep_client_ids = organization.clients.kept.peps.pluck(:id)

        organization.transactions.kept.for_year(year)
          .where(client_id: pep_client_ids)
          .where(transaction_type: %w[PURCHASE SALE])
          .count
      end

      # Q53 — a11305B: Total value of funds transferred by PEP clients for purchase/sale
      # Type: xbrli:monetaryItemType
      # Scope: Purchase and sale transactions only (NOT rentals)
      # Conditional: only when a11301 == "Oui"
      def a11305b
        return nil unless a11301 == "Oui"

        pep_client_ids = organization.clients.kept.peps.pluck(:id)

        organization.transactions.kept.for_year(year)
          .where(client_id: pep_client_ids)
          .where(transaction_type: %w[PURCHASE SALE])
          .sum(:transaction_value)
      end

      # Q54 — a11307: Total unique PEP beneficial owners of legal entities/trusts
      # and other legal constructions, broken down by PEP's primary nationality
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a11301 == "Oui"
      def a11307
        return nil unless a11301 == "Oui"

        le_trust_client_ids = organization.transactions.kept.for_year(year)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .select(:client_id)
          .distinct

        BeneficialOwner
          .where(client_id: le_trust_client_ids)
          .peps
          .where.not(nationality: nil)
          .group(:nationality)
          .count
      end

      # Q55 — a11309B: Total transactions (purchase/sale) by legal entities/trusts
      # whose beneficial owners are PEPs
      # Type: xbrli:integerItemType
      # Conditional: only when a11301 == "Oui"
      def a11309b
        return nil unless a11301 == "Oui"

        le_trust_client_ids_with_pep_bos = BeneficialOwner.peps
          .joins(:client)
          .where(clients: {organization_id: organization.id, client_type: "LEGAL_ENTITY"})
          .select(:client_id)
          .distinct

        organization.transactions.kept.for_year(year)
          .where(client_id: le_trust_client_ids_with_pep_bos)
          .where(transaction_type: %w[PURCHASE SALE])
          .count
      end

      # === Section 1.9: Virtual Asset Service Providers (PSAV) ===

      # Q56 — a13501B: Does your entity have clients that are VASPs (PSAV)?
      # Type: enum "Oui" / "Non" (settings-based)
      def a13501b
        setting_value_for("has_vasp_clients")
      end

      # Q57 — a13601A: Does your entity distinguish if PSAV clients are custodian wallet providers?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)
      def a13601a
        return nil unless a13501b == "Oui"
        setting_value_for("distinguishes_custodian_wallet_providers")
      end

      # Q58 — a13601CW: Does your entity have PSAV clients who are custodian wallet providers?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13601a)
      def a13601cw
        return nil unless a13601a == "Oui"
        setting_value_for("has_custodian_wallet_provider_clients")
      end

      # Q59 — a13603BB: Total unique PSAV clients who are custodian wallet providers
      # for purchases, sales, and rentals of real estate
      # Type: xbrli:integerItemType (scalar — NoCountryDimension)
      # Conditional: only when a13601cw == "Oui"
      def a13603bb
        return nil unless a13601cw == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "CUSTODIAN"})
          .distinct
          .count("clients.id")
      end

      # Q60 — a13604BB: Total value of funds transferred by custodian wallet provider
      # PSAV clients for purchase, sale, and rental of real estate
      # Type: xbrli:monetaryItemType
      # Conditional: only when a13601cw == "Oui"
      def a13604bb
        return nil unless a13601cw == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "CUSTODIAN"})
          .sum(:transaction_value)
      end

      # Q61 — a13601B: Does your entity distinguish whether PSAV clients are
      # virtual currency exchange providers?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)
      def a13601b
        return nil unless a13501b == "Oui"
        setting_value_for("distinguishes_exchange_providers")
      end

      # Q62 — a13601EP: Does your entity have PSAV clients who are
      # virtual currency exchange providers?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13601b)
      def a13601ep
        return nil unless a13601b == "Oui"
        setting_value_for("has_exchange_provider_clients")
      end

      # Q65 — a13601C: Does your entity distinguish if PSAV clients are ICO service providers?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)
      def a13601c
        return nil unless a13501b == "Oui"
        setting_value_for("distinguishes_ico_providers")
      end

      # Q66 — a13601ICO: Does your entity have PSAV clients who are ICO service providers?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13601c)
      def a13601ico
        return nil unless a13601c == "Oui"
        setting_value_for("has_ico_provider_clients")
      end

      # Q67 — a13603CACB: Total transactions by ICO service provider PSAV clients
      # for purchase, sale, and rental of real estate
      # Type: xbrli:integerItemType
      # Conditional: only when a13601ico == "Oui"
      def a13603cacb
        return nil unless a13601ico == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "ICO"})
          .count
      end

      # Q68 — a13604CB: Total value of funds transferred by ICO service provider
      # PSAV clients for purchase, sale, and rental of real estate
      # Type: xbrli:monetaryItemType
      # Conditional: only when a13601ico == "Oui"
      def a13604cb
        return nil unless a13601ico == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "ICO"})
          .sum(:transaction_value)
      end

      # Q69 — a13601C2: Does your entity distinguish if PSAV clients provide other services
      # not mentioned above?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)
      def a13601c2
        return nil unless a13501b == "Oui"
        setting_value_for("distinguishes_other_vasp_services")
      end

      # Q70 — a13601OTHER: Does your entity have PSAV clients who provide other services?
      # Type: enum "Oui" / "Non" (settings-based, conditional on a13601c2)
      def a13601other
        return nil unless a13601c2 == "Oui"
        setting_value_for("has_other_vasp_service_clients")
      end

      # Q71 — a13603DB: Total transactions by other-services PSAV clients
      # for purchase, sale, and rental of real estate
      # Type: xbrli:integerItemType
      # Conditional: only when a13601other == "Oui"
      def a13603db
        return nil unless a13601other == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "OTHER"})
          .count
      end

      # Q72 — a13604DB: Total value of funds transferred by other-services PSAV clients
      # for purchase, sale, and rental of real estate
      # Type: xbrli:monetaryItemType
      # Conditional: only when a13601other == "Oui"
      def a13604db
        return nil unless a13601other == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "OTHER"})
          .sum(:transaction_value)
      end

      # Q73 — a13602B: Unique custodian wallet provider PSAV clients
      # by country of establishment, for purchase, sale, and rental
      # Type: xbrli:integerItemType — dimensional by country (hash of counts)
      # Conditional: only when a13601cw == "Oui"
      def a13602b
        return nil unless a13601cw == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "CUSTODIAN"})
          .where.not(clients: {incorporation_country: nil})
          .distinct
          .group("clients.incorporation_country")
          .count("clients.id")
      end

      # Q64 — a13604AB: Total value of funds transferred by virtual currency exchange provider
      # PSAV clients for purchase, sale, and rental of real estate
      # Type: xbrli:monetaryItemType
      # Conditional: only when a13601ep == "Oui"
      def a13604ab
        return nil unless a13601ep == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "EXCHANGE"})
          .sum(:transaction_value)
      end

      # Q63 — a13603AB: Total transactions by virtual currency exchange provider PSAV clients
      # for purchase, sale, and rental of real estate
      # Type: xbrli:integerItemType
      # Conditional: only when a13601ep == "Oui"
      def a13603ab
        return nil unless a13601ep == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: "EXCHANGE"})
          .count
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
