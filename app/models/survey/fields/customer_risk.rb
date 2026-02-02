# frozen_string_literal: true

# Tab 1: Customer Risk Assessment
# Field methods for customer-related risk metrics
#
# Fields cover:
# - Client totals by type (natural persons, legal entities, trusts)
# - Client nationality and residence breakdowns
# - PEP (Politically Exposed Persons) statistics
# - VASP (Virtual Asset Service Provider) client statistics
# - High-net-worth individual tracking
# - Beneficial owner statistics
#
class Survey
  module Fields
    module CustomerRisk
      extend ActiveSupport::Concern
      include Helpers

      private

      # === Activity Indicators ===

      # Has the agency had any professional activity during the reporting period?
      def aactive
        year_transactions.exists? ? "Oui" : "Non"
      end

      # Specifically for purchase/sale activity
      def aactiveps
        year_transactions.purchases.or(year_transactions.sales).exists? ? "Oui" : "Non"
      end

      # Specifically for rental activity (monthly rent >= €10,000)
      def aactiverentals
        year_transactions.rentals.where(transaction_value: 10_000..).exists? ? "Oui" : "Non"
      end

      # === Client Totals ===

      # Total number of unique clients active during the period
      def a1101
        organization.clients.count
      end

      # Clients who are Monegasque nationals
      def a1102
        clients_kept.where(nationality: "MC").count
      end

      # Clients who are foreign residents (not MC nationals but residents)
      def a1103
        clients_kept.where(residence_status: "RESIDENT").where.not(nationality: "MC").count
      end

      # Clients who are non-residents
      def a1104
        clients_kept.where(residence_status: "NON_RESIDENT").count
      end

      # === Natural Person Statistics ===

      # Transactions by individual clients for purchase/sale
      def a1403b
        year_transactions
          .by_client
          .joins(:client)
          .merge(Client.natural_persons)
          .where(transaction_type: %w[PURCHASE SALE])
          .count
      end

      # Total funds transferred by individual clients
      def a1404b
        year_transactions
          .joins(:client)
          .merge(Client.natural_persons)
          .sum(:transaction_value)
      end

      # Individual clients with rental activity
      def a1401r
        clients_kept
          .natural_persons
          .joins(:transactions)
          .merge(Transaction.rentals.for_year(year))
          .distinct
          .count
      end

      # Rental transactions by individual clients
      def a1403r
        year_transactions
          .by_client
          .joins(:client)
          .merge(Client.natural_persons)
          .rentals
          .where(transaction_value: 10_000..)
          .sum(:rental_duration_months)
      end

      # === Legal Entity Statistics ===

      # Transactions by legal entity clients
      def a1502b
        purchases_and_sales = year_transactions
          .by_client
          .joins(:client)
          .merge(Client.legal_entities)
          .where(transaction_type: %w[PURCHASE SALE])
          .count

        rental_months = year_transactions
          .by_client
          .joins(:client)
          .merge(Client.legal_entities)
          .rentals
          .where(transaction_value: 10_000..)
          .sum(:rental_duration_months)

        purchases_and_sales + rental_months
      end

      # Total funds from legal entity transactions
      def a1503b
        year_transactions
          .joins(:client)
          .merge(Client.legal_entities)
          .sum(:transaction_value)
      end

      # Does the entity identify Monaco legal entity types?
      def a155
        setting_value("a155") || "Non"
      end

      # === Trust Statistics ===

      # Does the entity identify trusts?
      def a1802btola
        clients_kept.trusts.exists? ? "Oui" : "Non"
      end

      # Number of trust clients
      def a1802tola
        clients_kept.trusts.count
      end

      # Monaco-based trusts
      def a1807atola
        clients_kept.trusts.where(country_code: "MC").count
      end

      # Has trust clients
      def a1801
        clients_kept.trusts.exists? ? "Oui" : "Non"
      end

      # Can provide trust transaction info
      def a11001btola
        a1806tola.positive? ? "Oui" : "Non"
      end

      # Transactions by trust clients
      def a1806tola
        purchases_and_sales = year_transactions
          .by_client
          .joins(:client)
          .merge(Client.trusts)
          .where(transaction_type: %w[PURCHASE SALE])
          .count

        rental_months = year_transactions
          .by_client
          .joins(:client)
          .merge(Client.trusts)
          .rentals
          .where(transaction_value: 10_000..)
          .sum(:rental_duration_months)

        purchases_and_sales + rental_months
      end

      # Total funds from trust transactions
      def a1807tola
        year_transactions
          .joins(:client)
          .merge(Client.trusts)
          .sum(:transaction_value)
      end

      # Description of other legal arrangements
      def a11006
        setting_value("a11006")
      end

      # === PEP (Politically Exposed Person) Statistics ===

      # Has PEP clients
      def a11301
        clients_kept.peps.exists? ? "Oui" : "Non"
      end

      # Transactions by PEP clients
      def a11304b
        year_transactions
          .joins(:client)
          .merge(Client.peps)
          .count
      end

      # Total funds from PEP transactions
      def a11305b
        year_transactions
          .joins(:client)
          .merge(Client.peps)
          .sum(:transaction_value)
      end

      # Transactions with PEP beneficial owners
      def a11309b
        year_transactions
          .joins(client: :beneficial_owners)
          .where(beneficial_owners: {is_pep: true})
          .distinct
          .count
      end

      # === VASP (Virtual Asset Service Provider) Statistics ===

      # Has VASP clients
      def a13501b
        clients_kept.vasps.exists? ? "Oui" : "Non"
      end

      # === VASP Custodian Statistics ===

      def a13601a
        setting_value("a13601a") || "Non"
      end

      def a13601cw
        clients_kept.where(is_vasp: true, vasp_type: "CUSTODIAN").exists? ? "Oui" : "Non"
      end

      def a13603bb
        vasp_transactions_by_type("CUSTODIAN")
      end

      def a13604bb
        vasp_funds_by_type("CUSTODIAN")
      end

      # === VASP Exchange Statistics ===

      def a13601b
        setting_value("a13601b") || "Non"
      end

      def a13601ep
        clients_kept.where(is_vasp: true, vasp_type: "EXCHANGE").exists? ? "Oui" : "Non"
      end

      def a13603ab
        vasp_transactions_by_type("EXCHANGE")
      end

      def a13604ab
        vasp_funds_by_type("EXCHANGE")
      end

      # === VASP ICO Statistics ===

      def a13601c
        setting_value("a13601c") || "Non"
      end

      def a13601ico
        clients_kept.where(is_vasp: true, vasp_type: "ICO").exists? ? "Oui" : "Non"
      end

      def a13603cacb
        vasp_transactions_by_type("ICO")
      end

      def a13604cb
        vasp_funds_by_type("ICO")
      end

      # === VASP Other Statistics ===

      def a13601c2
        setting_value("a13601c2") || "Non"
      end

      def a13601other
        clients_kept.where(is_vasp: true, vasp_type: "OTHER").exists? ? "Oui" : "Non"
      end

      def a13603db
        vasp_transactions_by_type("OTHER")
      end

      def a13604db
        vasp_funds_by_type("OTHER")
      end

      # Does entity provide other VASP services
      def a13601
        setting_value("a13601") || "Non"
      end

      def a13604e
        setting_value("a13604e")
      end

      # === Beneficial Owner Statistics ===

      # Can identify BO nationality
      def a1204s
        setting_value("a1204s") || "Oui"
      end

      # Can identify BOs with 25%+ ownership
      def a1204o
        setting_value("a1204o") || "Oui"
      end

      # Records BO residence
      def a1203d
        setting_value("a1203d") || "Oui"
      end

      # Records dual nationality
      def a1203
        setting_value("a1203") || "Non"
      end

      # Ownership structure documentation
      def ac171
        setting_value("ac171") || "Oui"
      end

      # === High-Net-Worth Individual Tracking ===

      # Tracks HNWIs (High Net Worth Individuals)
      def a11201bcd
        setting_value("a11201bcd") || "Non"
      end

      # Tracks UHNWIs (Ultra High Net Worth Individuals)
      def a11201bcdu
        setting_value("a11201bcdu") || "Non"
      end

      # === Transaction Statistics ===

      # Transactions BY clients (client pays directly, funds don't flow through agency)
      # AMSF counts each rental month >= €10,000 as a separate transaction
      def a1105b
        purchases_and_sales = year_transactions.by_client.where(transaction_type: %w[PURCHASE SALE]).count

        rental_months = year_transactions.by_client
          .rentals
          .where(transaction_value: 10_000..)
          .sum(:rental_duration_months)

        purchases_and_sales + rental_months
      end

      # Funds transferred BY clients (client pays directly)
      def a1106b
        year_transactions.by_client.sum(:transaction_value)
      end

      # Funds transferred for rentals
      def a1106brentals
        year_transactions.rentals.sum(:transaction_value)
      end

      # Transactions WITH clients (funds flow through agency)
      def a1105w
        year_transactions.with_client.count
      end

      # Funds transferred WITH clients (funds flow through agency)
      def a1106w
        year_transactions.with_client.sum(:transaction_value)
      end

      # === Monaco Business Sector Statistics ===
      # Counts of clients in various Monaco high-risk business sectors

      def a11502b
        clients_by_sector("LEGAL_SERVICES")
      end

      def a11602b
        clients_by_sector("ACCOUNTING")
      end

      def a11702b
        clients_by_sector("NOMINEE_SHAREHOLDER")
      end

      def a11802b
        clients_by_sector("BEARER_INSTRUMENTS")
      end

      def a12002b
        clients_by_sector("REAL_ESTATE")
      end

      def a12102b
        clients_by_sector("NMPPP")
      end

      def a12202b
        clients_by_sector("TCSP")
      end

      def a12302b
        clients_by_sector("MULTI_FAMILY_OFFICE")
      end

      def a12302c
        clients_by_sector("SINGLE_FAMILY_OFFICE")
      end

      def a12402b
        clients_by_sector("COMPLEX_STRUCTURES")
      end

      def a12502b
        clients_by_sector("CASH_INTENSIVE")
      end

      def a12602b
        clients_by_sector("PREPAID_CARDS")
      end

      def a12702b
        clients_by_sector("ART_ANTIQUITIES")
      end

      def a12802b
        clients_by_sector("IMPORT_EXPORT")
      end

      def a12902b
        clients_by_sector("HIGH_VALUE_GOODS")
      end

      def a13002b
        clients_by_sector("NPO")
      end

      def a13202b
        clients_by_sector("GAMBLING")
      end

      def a13302b
        clients_by_sector("CONSTRUCTION")
      end

      def a13402b
        clients_by_sector("EXTRACTIVE")
      end

      def a13702b
        clients_by_sector("DEFENSE_WEAPONS")
      end

      def a13802b
        clients_by_sector("YACHTING")
      end

      def a13902b
        clients_by_sector("SPORTS_AGENTS")
      end

      def a14102b
        clients_by_sector("FUND_MANAGEMENT")
      end

      def a14202b
        clients_by_sector("HOLDING_COMPANY")
      end

      def a14302b
        clients_by_sector("AUCTIONEERS")
      end

      def a14402b
        clients_by_sector("CAR_DEALERS")
      end

      def a14502b
        clients_by_sector("GOVERNMENT")
      end

      def a14602b
        clients_by_sector("AIRCRAFT_JETS")
      end

      def a14702b
        clients_by_sector("TRANSPORT")
      end

      # === Section Comments ===

      def a14801
        setting_value("a14801").present? ? "Oui" : "Non"
      end

      def a14001
        setting_value("a14001")
      end

      # === French-labeled fields (ir_*) ===

      # air129 - specific regulatory question
      def air129
        setting_value("air129") || "Non"
      end

      # Purchases made with specific intent
      def air1210
        setting_value("air1210")&.to_i || 0
      end

      # === Dimensional Breakdowns (by nationality/country) ===

      # BO nationality breakdown (percentages)
      # Returns Hash of ISO country code => percentage for XBRL dimensional output
      def a1204s1
        counts = beneficial_owners_base
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count

        total = counts.values.sum.to_f
        return {} if total.zero?

        counts.transform_values { |count| (count / total * 100).round(2) }
      end

      # BOs by direct/indirect control, grouped by nationality
      def a1202o
        beneficial_owners_base
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # BOs representing legal entities, grouped by nationality
      def a1202ob
        beneficial_owners_base
          .joins(:client)
          .merge(Client.legal_entities)
          .where.not(beneficial_owners: {nationality: [nil, ""]})
          .group(:nationality)
          .count
      end

      # BOs with 25%+ ownership, grouped by nationality
      def a120425o
        beneficial_owners_base
          .where("ownership_percentage >= ?", 25)
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Foreign resident BOs (resident in MC but not MC national), grouped by nationality
      def a1207o
        beneficial_owners_base
          .where(residence_country: "MC")
          .where.not(nationality: ["MC", nil, ""])
          .group(:nationality)
          .count
      end

      # Non-resident BOs (not resident in MC), grouped by nationality
      def a1210o
        beneficial_owners_base
          .where.not(residence_country: ["MC", nil, ""])
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Individuals grouped by nationality
      def a1401
        clients_kept
          .natural_persons
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Legal entities grouped by country
      def a1501
        clients_kept
          .legal_entities
          .where.not(country_code: [nil, ""])
          .group(:country_code)
          .count
      end

      # HNWI BOs grouped by nationality
      def a11206b
        # Would need HNWI flag on beneficial_owners - return empty hash for now
        {}
      end

      # UHNWI BOs grouped by nationality
      def a112012b
        # Would need UHNWI flag on beneficial_owners - return empty hash for now
        {}
      end

      # Professional trustees grouped by nationality
      def a1808
        clients_kept
          .trusts
          .where(professional_category: "PROFESSIONAL_TRUSTEE")
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # Professional trustees grouped by trust country
      def a1809
        clients_kept
          .trusts
          .where(professional_category: "PROFESSIONAL_TRUSTEE")
          .where.not(country_code: [nil, ""])
          .group(:country_code)
          .count
      end

      # PEP clients grouped by residence country
      def a11302res
        clients_kept
          .peps
          .where.not(residence_country: [nil, ""])
          .group(:residence_country)
          .count
      end

      # PEP clients grouped by nationality
      def a11302
        clients_kept
          .peps
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # PEP beneficial owners grouped by nationality
      def a11307
        beneficial_owners_base
          .where(is_pep: true)
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
      end

      # VASP Custodian clients grouped by country
      def a13602b
        vasp_clients_grouped_by_country("CUSTODIAN")
      end

      # VASP Exchange clients grouped by country
      def a13602a
        vasp_clients_grouped_by_country("EXCHANGE")
      end

      # VASP ICO clients grouped by country
      def a13602c
        vasp_clients_grouped_by_country("ICO")
      end

      # VASP Other clients grouped by country
      def a13602d
        vasp_clients_grouped_by_country("OTHER")
      end

      # Secondary nationalities for individuals
      def a1402
        # Would need secondary_nationality field - return empty hash for now
        {}
      end
    end
  end
end
