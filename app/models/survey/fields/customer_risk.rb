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

      private

      # === Activity Indicators ===

      # Has the agency had any professional activity during the reporting period?
      def has_activity
        year_transactions.exists? ? "Oui" : "Non"
      end

      # Specifically for purchase/sale activity
      def has_activity_purchase_sale
        year_transactions.purchases.or(year_transactions.sales).exists? ? "Oui" : "Non"
      end

      # Specifically for rental activity
      def has_activity_rentals
        year_transactions.rentals.exists? ? "Oui" : "Non"
      end

      # === Client Totals ===

      # Total number of unique clients active during the period
      def total_clients
        organization.clients.count
      end

      # Clients who are Monegasque nationals
      def clients_nationals
        clients_kept.where(nationality: "MC").count
      end

      # Clients who are foreign residents (not MC nationals but residents)
      def clients_foreign_residents
        clients_kept.where(residence_status: "RESIDENT").where.not(nationality: "MC").count
      end

      # Clients who are non-residents
      def clients_non_residents
        clients_kept.where(residence_status: "NON_RESIDENT").count
      end

      # === Natural Person Statistics ===

      # Transactions by individual clients for purchase/sale
      def individual_transactions_purchase_sale
        year_transactions
          .joins(:client)
          .merge(Client.natural_persons)
          .where(transaction_type: %w[PURCHASE SALE])
          .count
      end

      # Total funds transferred by individual clients
      def individual_funds_transferred
        year_transactions
          .joins(:client)
          .merge(Client.natural_persons)
          .sum(:transaction_value)
      end

      # Individual clients with rental activity
      def individuals_rentals
        clients_kept
          .natural_persons
          .joins(:transactions)
          .merge(Transaction.rentals.for_year(year))
          .distinct
          .count
      end

      # Rental transactions by individual clients
      def individual_transactions_rentals
        year_transactions
          .joins(:client)
          .merge(Client.natural_persons)
          .rentals
          .count
      end

      # === Legal Entity Statistics ===

      # Transactions by legal entity clients
      def legal_entity_transactions
        year_transactions
          .joins(:client)
          .merge(Client.legal_entities)
          .count
      end

      # Total funds from legal entity transactions
      def legal_entity_funds
        year_transactions
          .joins(:client)
          .merge(Client.legal_entities)
          .sum(:transaction_value)
      end

      # Does the entity identify Monaco legal entity types?
      def identifies_monaco_legal_entity_types
        setting_value("identifies_monaco_legal_entity_types") || "Non"
      end

      # === Trust Statistics ===

      # Does the entity identify trusts?
      def identifies_trusts
        clients_kept.trusts.exists? ? "Oui" : "Non"
      end

      # Number of trust clients
      def trusts_count
        clients_kept.trusts.count
      end

      # Monaco-based trusts
      def monaco_trusts
        clients_kept.trusts.where(country_code: "MC").count
      end

      # Has trust clients
      def has_trust_clients
        clients_kept.trusts.exists? ? "Oui" : "Non"
      end

      # Can provide trust transaction info
      def has_trust_transaction_info
        trust_transactions.positive? ? "Oui" : "Non"
      end

      # Transactions by trust clients
      def trust_transactions
        year_transactions
          .joins(:client)
          .merge(Client.trusts)
          .count
      end

      # Total funds from trust transactions
      def trust_funds
        year_transactions
          .joins(:client)
          .merge(Client.trusts)
          .sum(:transaction_value)
      end

      # Description of other legal arrangements
      def other_arrangements_desc
        setting_value("other_arrangements_desc")
      end

      # === PEP (Politically Exposed Person) Statistics ===

      # Has PEP clients
      def has_pep_clients
        clients_kept.peps.exists? ? "Oui" : "Non"
      end

      # Transactions by PEP clients
      def pep_transactions
        year_transactions
          .joins(:client)
          .merge(Client.peps)
          .count
      end

      # Total funds from PEP transactions
      def pep_funds_transferred
        year_transactions
          .joins(:client)
          .merge(Client.peps)
          .sum(:transaction_value)
      end

      # Transactions with PEP beneficial owners
      def pep_bo_transactions
        year_transactions
          .joins(client: :beneficial_owners)
          .where(beneficial_owners: {is_pep: true})
          .distinct
          .count
      end

      # === VASP (Virtual Asset Service Provider) Statistics ===

      # Has VASP clients
      def has_vasp_clients
        clients_kept.vasps.exists? ? "Oui" : "Non"
      end

      # === VASP Custodian Statistics ===

      def identifies_vasp_custodians
        setting_value("identifies_vasp_custodians") || "Non"
      end

      def has_vasp_custodian_clients
        clients_kept.where(is_vasp: true, vasp_type: "CUSTODIAN").exists? ? "Oui" : "Non"
      end

      def vasp_custodian_transactions
        vasp_transactions_by_type("CUSTODIAN")
      end

      def vasp_custodian_funds
        vasp_funds_by_type("CUSTODIAN")
      end

      # === VASP Exchange Statistics ===

      def identifies_vasp_exchanges
        setting_value("identifies_vasp_exchanges") || "Non"
      end

      def has_vasp_exchange_clients
        clients_kept.where(is_vasp: true, vasp_type: "EXCHANGE").exists? ? "Oui" : "Non"
      end

      def vasp_exchange_transactions
        vasp_transactions_by_type("EXCHANGE")
      end

      def vasp_exchange_funds
        vasp_funds_by_type("EXCHANGE")
      end

      # === VASP ICO Statistics ===

      def identifies_vasp_ico
        setting_value("identifies_vasp_ico") || "Non"
      end

      def has_vasp_ico_clients
        clients_kept.where(is_vasp: true, vasp_type: "ICO").exists? ? "Oui" : "Non"
      end

      def vasp_ico_transactions
        vasp_transactions_by_type("ICO")
      end

      def vasp_ico_funds
        vasp_funds_by_type("ICO")
      end

      # === VASP Other Statistics ===

      def identifies_vasp_other
        setting_value("identifies_vasp_other") || "Non"
      end

      def has_vasp_other_clients
        clients_kept.where(is_vasp: true, vasp_type: "OTHER").exists? ? "Oui" : "Non"
      end

      def vasp_other_transactions
        vasp_transactions_by_type("OTHER")
      end

      def vasp_other_funds
        vasp_funds_by_type("OTHER")
      end

      # Does entity provide other VASP services
      def vasp_other_services
        setting_value("vasp_other_services") || "Non"
      end

      def vasp_other_services_desc
        setting_value("vasp_other_services_desc")
      end

      # === Beneficial Owner Statistics ===

      # Can identify BO nationality
      def can_identify_bo_nationality
        setting_value("can_identify_bo_nationality") || "Oui"
      end

      # Can identify BOs with 25%+ ownership
      def can_identify_25pct_bo
        setting_value("can_identify_25pct_bo") || "Oui"
      end

      # Records BO residence
      def records_bo_residence
        setting_value("records_bo_residence") || "Oui"
      end

      # Records dual nationality
      def records_dual_nationality
        setting_value("records_dual_nationality") || "Non"
      end

      # Ownership structure documentation
      def ownership_structure
        setting_value("ownership_structure") || "Oui"
      end

      # === High-Net-Worth Individual Tracking ===

      # Tracks HNWIs (High Net Worth Individuals)
      def tracks_hnwi
        setting_value("tracks_hnwi") || "Non"
      end

      # Tracks UHNWIs (Ultra High Net Worth Individuals)
      def tracks_uhnwi
        setting_value("tracks_uhnwi") || "Non"
      end

      # === Transaction Statistics ===

      # Transactions BY clients (client is principal)
      def transactions_by_clients
        year_transactions.by_client.count
      end

      # Funds transferred BY clients
      def funds_transferred_by_clients
        year_transactions.by_client.sum(:transaction_value)
      end

      # Funds transferred for rentals
      def funds_transferred_rentals
        year_transactions.rentals.sum(:transaction_value)
      end

      # Transactions WITH clients (agency represents client)
      def transactions_with_clients
        year_transactions.with_client.count
      end

      # Funds transferred WITH clients
      def funds_transferred_with_clients
        year_transactions.with_client.sum(:transaction_value)
      end

      # === Monaco Business Sector Statistics ===
      # Counts of clients in various Monaco high-risk business sectors

      def monaco_lawyers
        clients_by_sector("LEGAL_SERVICES")
      end

      def monaco_accountants
        clients_by_sector("ACCOUNTING")
      end

      def monaco_nominee_shareholders
        clients_by_sector("NOMINEE_SHAREHOLDER")
      end

      def monaco_bearer_instruments
        clients_by_sector("BEARER_INSTRUMENTS")
      end

      def monaco_real_estate_agents
        clients_by_sector("REAL_ESTATE")
      end

      def monaco_nmppp
        clients_by_sector("NMPPP")
      end

      def monaco_tcsp
        clients_by_sector("TCSP")
      end

      def monaco_multi_family_offices
        clients_by_sector("MULTI_FAMILY_OFFICE")
      end

      def monaco_single_family_offices
        clients_by_sector("SINGLE_FAMILY_OFFICE")
      end

      def monaco_complex_structures
        clients_by_sector("COMPLEX_STRUCTURES")
      end

      def monaco_cash_intensive
        clients_by_sector("CASH_INTENSIVE")
      end

      def monaco_prepaid_cards
        clients_by_sector("PREPAID_CARDS")
      end

      def monaco_art_antiquities
        clients_by_sector("ART_ANTIQUITIES")
      end

      def monaco_import_export
        clients_by_sector("IMPORT_EXPORT")
      end

      def monaco_high_value_goods
        clients_by_sector("HIGH_VALUE_GOODS")
      end

      def monaco_npo
        clients_by_sector("NPO")
      end

      def monaco_gambling
        clients_by_sector("GAMBLING")
      end

      def monaco_construction
        clients_by_sector("CONSTRUCTION")
      end

      def monaco_extractive
        clients_by_sector("EXTRACTIVE")
      end

      def monaco_defense_weapons
        clients_by_sector("DEFENSE_WEAPONS")
      end

      def monaco_yachting
        clients_by_sector("YACHTING")
      end

      def monaco_sports_agents
        clients_by_sector("SPORTS_AGENTS")
      end

      def monaco_fund_management
        clients_by_sector("FUND_MANAGEMENT")
      end

      def monaco_holding_companies
        clients_by_sector("HOLDING_COMPANY")
      end

      def monaco_auctioneers
        clients_by_sector("AUCTIONEERS")
      end

      def monaco_car_dealers
        clients_by_sector("CAR_DEALERS")
      end

      def monaco_government_sector
        clients_by_sector("GOVERNMENT")
      end

      def monaco_aircraft_jets
        clients_by_sector("AIRCRAFT_JETS")
      end

      def monaco_transport
        clients_by_sector("TRANSPORT")
      end

      # === Section Comments ===

      def section_comments_risks
        setting_value("section_comments_risks").present? ? "Oui" : "Non"
      end

      def section_comments_clients
        setting_value("section_comments_clients")
      end

      # === French-labeled fields (ir_*) ===

      # ir_129 - specific regulatory question
      def ir_129
        setting_value("ir_129") || "Non"
      end

      # Purchases made with specific intent
      def combien_d_achats_ont_ils_ete_effectues_dans_le_but
        setting_value("combien_d_achats_ont_ils_ete_effectues_dans_le_but")&.to_i || 0
      end

      # === Dimensional Breakdowns (by nationality/country) ===

      # BO nationality breakdown
      def bo_nationality_breakdown
        beneficial_owners_base
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
          .to_json
      end

      # BOs by direct/indirect and nationality
      def bo_direct_indirect_by_nationality
        # Returns count - dimensional breakdown would be in separate field
        beneficial_owners_base.count
      end

      # BOs representing legal entities
      def bo_representing_legal_entity
        beneficial_owners_base
          .joins(:client)
          .merge(Client.legal_entities)
          .count
      end

      # BOs with 25%+ ownership by nationality
      def bo_25pct_by_nationality
        beneficial_owners_base
          .where("ownership_percentage >= ?", 25)
          .count
      end

      # Foreign resident BOs by nationality (resident in MC but not MC national)
      def bo_foreign_residents_by_nationality
        beneficial_owners_base
          .where(residence_country: "MC")
          .where.not(nationality: "MC")
          .count
      end

      # Non-resident BOs by nationality (not resident in MC)
      def bo_non_residents_by_nationality
        beneficial_owners_base
          .where.not(residence_country: ["MC", nil, ""])
          .count
      end

      # Individuals by nationality
      def individuals_by_nationality
        clients_kept
          .natural_persons
          .where.not(nationality: [nil, ""])
          .group(:nationality)
          .count
          .values
          .sum
      end

      # Legal entities by country
      def legal_entities_by_country
        clients_kept
          .legal_entities
          .where.not(country_code: [nil, ""])
          .count
      end

      # HNWI BOs by nationality
      def hnwi_bo_by_nationality
        # Would need HNWI flag on beneficial_owners - return 0 for now
        0
      end

      # UHNWI BOs by nationality
      def uhnwi_bo_by_nationality
        # Would need UHNWI flag on beneficial_owners - return 0 for now
        0
      end

      # Professional trustees by nationality
      def professional_trustees_by_nationality
        clients_kept
          .trusts
          .where(professional_category: "PROFESSIONAL_TRUSTEE")
          .count
      end

      # Professional trustees by trust country
      def professional_trustees_by_trust_country
        clients_kept
          .trusts
          .where(professional_category: "PROFESSIONAL_TRUSTEE")
          .where.not(country_code: [nil, ""])
          .count
      end

      # PEP clients by residence
      def pep_clients_by_residence
        clients_kept
          .peps
          .where.not(residence_country: [nil, ""])
          .count
      end

      # PEP clients by nationality
      def pep_clients_by_nationality
        clients_kept
          .peps
          .where.not(nationality: [nil, ""])
          .count
      end

      # PEP beneficial owners count
      def pep_beneficial_owners
        beneficial_owners_base.where(is_pep: true).count
      end

      # VASP by country breakdowns
      def vasp_custodian_by_country
        vasp_clients_by_country("CUSTODIAN")
      end

      def vasp_exchange_by_country
        vasp_clients_by_country("EXCHANGE")
      end

      def vasp_ico_by_country
        vasp_clients_by_country("ICO")
      end

      def vasp_other_by_country
        vasp_clients_by_country("OTHER")
      end

      # Secondary nationalities for individuals
      def individuals_secondary_nationalities
        # Would need secondary_nationality field - return 0 for now
        0
      end

      # === Helper Methods ===

      def clients_kept
        organization.clients.kept
      end

      def year_transactions
        organization.transactions.kept.for_year(year)
      end

      def beneficial_owners_base
        BeneficialOwner.joins(:client)
          .merge(Client.kept)
          .where(clients: {organization_id: organization.id})
      end

      def setting_value(key)
        settings_cache[key]
      end

      def settings_cache
        @settings_cache ||= organization.settings
          .where.not(key: [nil, ""])
          .index_by(&:key)
          .transform_values(&:typed_value)
      end

      def clients_by_sector(sector)
        clients_kept.where(business_sector: sector).count
      end

      def vasp_transactions_by_type(vasp_type)
        year_transactions
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: vasp_type})
          .count
      end

      def vasp_funds_by_type(vasp_type)
        year_transactions
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: vasp_type})
          .sum(:transaction_value)
      end

      def vasp_clients_by_country(vasp_type)
        clients_kept
          .where(is_vasp: true, vasp_type: vasp_type)
          .where.not(country_code: [nil, ""])
          .count
      end
    end
  end
end
