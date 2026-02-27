# frozen_string_literal: true

class Survey
  module Fields
    module ProductsServicesRisk
      # Q112 — a2101W: Does entity accept or carry out cheque operations with clients?
      # Type: enum (Oui/Non) — settings-based
      def a2101w
        setting_value_for("accepts_cheque_operations")
      end

      # Q113 — a2101WRP: Did entity accept or carry out cheque operations during reporting period?
      # Type: enum (Oui/Non) — settings-based, conditional on a2101w
      def a2101wrp
        return nil unless a2101w == "Oui"
        setting_value_for("had_cheque_operations_in_period")
      end

      # Q114 — a2102W: Total number of cheque operations (incoming and outgoing) with clients
      # Type: xbrli:integerItemType — computed, conditional on a2101wrp
      def a2102w
        return nil unless a2101wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "CHECK")
          .count
      end

      # Q115 — a2102BW: Total value of cheque operations (incoming and outgoing) with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2101wrp
      def a2102bw
        return nil unless a2101wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "CHECK")
          .sum(:transaction_value)
      end

      # Q116 — a2101B: Did clients accept or perform cheque operations during reporting period?
      # Type: enum (Oui/Non) — settings-based
      def a2101b
        setting_value_for("clients_performed_cheque_operations")
      end

      # Q117 — a2102B: Total number of cheque operations (incoming and outgoing) by clients
      # Type: xbrli:integerItemType — computed, conditional on a2101b
      def a2102b
        return nil unless a2101b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "CHECK")
          .count
      end

      # Q118 — a2102BB: Total value of cheque operations (incoming and outgoing) by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2101b
      def a2102bb
        return nil unless a2101b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "CHECK")
          .sum(:transaction_value)
      end

      # Q119 — a2104W: Does entity accept or make electronic wire transfers with clients?
      # Type: enum (Oui/Non) — settings-based
      def a2104w
        setting_value_for("accepts_wire_transfers")
      end

      # Q120 — a2104WRP: Did entity accept or make electronic wire transfers with clients in period?
      # Type: enum (Oui/Non) — settings-based, conditional on a2104w
      def a2104wrp
        return nil unless a2104w == "Oui"
        setting_value_for("had_wire_transfers_in_period")
      end

      # Q121 — a2105W: Total electronic wire transfer operations with clients
      # Type: xbrli:integerItemType — computed, conditional on a2104wrp
      def a2105w
        return nil unless a2104wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "WIRE")
          .count
      end

      # Q122 — a2105BW: Total value of electronic wire transfers with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2104wrp
      def a2105bw
        return nil unless a2104wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "WIRE")
          .sum(:transaction_value)
      end

      # Q123 — a2104B: Did clients accept or make electronic wire transfers in period?
      # Type: enum (Oui/Non) — settings-based
      def a2104b
        setting_value_for("clients_performed_wire_transfers")
      end

      # Q124 — a2105B: Total electronic wire transfer operations by clients
      # Type: xbrli:integerItemType — computed, conditional on a2104b
      def a2105b
        return nil unless a2104b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "WIRE")
          .count
      end

      # Q125 — a2105BB: Total value of electronic wire transfers by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2104b
      def a2105bb
        return nil unless a2104b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "WIRE")
          .sum(:transaction_value)
      end

      # Q126 — a2107W: Does entity accept or carry out cash operations with clients?
      # Type: enum (Oui/Non) — settings-based
      def a2107w
        setting_value_for("accepts_cash_operations")
      end

      # Q127 — a2107WRP: Did entity accept or carry out cash operations with clients during reporting period?
      # Type: enum (Oui/Non) — settings-based, conditional on a2107w
      def a2107wrp
        return nil unless a2107w == "Oui"
        setting_value_for("had_cash_operations_in_period")
      end

      # Q128 — a2108W: Total number of cash operations with clients
      # Type: xbrli:integerItemType — computed, conditional on a2107wrp
      def a2108w
        return nil unless a2107wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .count
      end

      # Q129 — a2109W: Total value of cash operations with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107wrp
      def a2109w
        return nil unless a2107wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .sum(:cash_amount)
      end

      # Q130 — aG24010W: Total value of cash in foreign currencies with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107wrp
      def ag24010w
        return nil unless a2107wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .sum(:foreign_currency_cash_amount)
      end

      # Q131 — a2110W: Cash operations >= 10,000 EUR with clients
      # Type: xbrli:integerItemType — computed, conditional on a2107wrp
      def a2110w
        return nil unless a2107wrp == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount >= ?", 10_000)
          .count
      end

      # Q132 — a2113W: Can entity distinguish cash operations > 100,000 EUR?
      # Type: enum (Oui/Non) — settings-based, conditional on a2107wrp
      def a2113w
        return nil unless a2107wrp == "Oui"
        setting_value_for("can_distinguish_cash_over_100k")
      end

      # Q133 — a2113AW: Cash ops with natural persons > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113w
      def a2113aw
        return nil unless a2113w == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount > ?", 100_000)
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .count
      end

      # Q134 — a2114A: Cash ops with Monegasque legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113w
      def a2114a
        return nil unless a2113w == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount > ?", 100_000)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", incorporation_country: "MC"})
          .count
      end

      # Q135 — a2115AW: Cash ops with foreign legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113w
      def a2115aw
        return nil unless a2113w == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount > ?", 100_000)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {incorporation_country: "MC"})
          .count
      end

      # Q136 — a2107B: Did clients perform cash operations?
      # Type: enum (Oui/Non) — settings-based
      def a2107b
        setting_value_for("clients_performed_cash_operations")
      end

      # Q137 — a2108B: Total cash operations count by clients
      # Type: xbrli:integerItemType — computed, conditional on a2107b
      def a2108b
        return nil unless a2107b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .count
      end

      # Q138 — a2109B: Total value of cash operations by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107b
      def a2109b
        return nil unless a2107b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .sum(:cash_amount)
      end

      # Q139 — aG24010B: Total value of cash in foreign currencies by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107b
      def ag24010b
        return nil unless a2107b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .sum(:foreign_currency_cash_amount)
      end

      # Q140 — a2110B: Cash operations >= 10,000 EUR by clients
      # Type: xbrli:integerItemType — computed, conditional on a2107b
      def a2110b
        return nil unless a2107b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount >= ?", 10_000)
          .count
      end

      # Q141 — a2113B: Can entity distinguish cash ops > 100,000 EUR by clients?
      # Type: enum (Oui/Non) — settings-based, conditional on a2107b
      def a2113b
        return nil unless a2107b == "Oui"
        setting_value_for("can_distinguish_client_cash_over_100k")
      end

      # Q142 — a2113AB: Cash ops by natural persons > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113b
      def a2113ab
        return nil unless a2113b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount > ?", 100_000)
          .joins(:client)
          .where(clients: {client_type: "NATURAL_PERSON"})
          .count
      end

      # Q143 — a2114AB: Cash ops by Monegasque legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113b
      def a2114ab
        return nil unless a2113b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount > ?", 100_000)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY", incorporation_country: "MC"})
          .count
      end

      # Q144 — a2115AB: Cash ops by foreign legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113b
      def a2115ab
        return nil unless a2113b == "Oui"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: %w[CASH MIXED])
          .where("cash_amount > ?", 100_000)
          .joins(:client)
          .where(clients: {client_type: "LEGAL_ENTITY"})
          .where.not(clients: {incorporation_country: "MC"})
          .count
      end

      # Q145 — a2201A: Does entity accept or conduct cryptocurrency operations with clients?
      # Type: enum (Oui/Non) — settings-based
      def a2201a
        setting_value_for("accepts_cryptocurrency_operations")
      end

      # Q146 — a2201D: Plans to accept virtual currency payments next year?
      # Type: enum (Oui/Non) — settings-based
      def a2201d
        setting_value_for("plans_to_accept_virtual_currencies")
      end

      # Q147 — a2202: Does entity have business relations with virtual asset platforms?
      # Type: enum (Oui/Non) — settings-based
      def a2202
        setting_value_for("has_virtual_asset_platform_relations")
      end

      # Q148 — a2203: Name the virtual asset platforms
      # Type: xbrli:stringItemType — settings-based, conditional on a2202
      def a2203
        return nil unless a2202 == "Oui"
        setting_value_for("virtual_asset_platform_names")
      end

      # Q149 — aIR233: Total unique clients by country for purchase/sale (dimensional)
      # Type: xbrli:integerItemType — dimensional by country
      def air233
        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .distinct
          .count(:client_id)
      end

      # Q150 — aIR233B: How many unique clients were buyers?
      # Type: xbrli:integerItemType — computed
      def air233b
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "PURCHASE")
          .distinct
          .count(:client_id)
      end

      # Q151 — aIR233S: How many unique clients were sellers?
      # Type: xbrli:integerItemType — computed
      def air233s
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "SALE")
          .distinct
          .count(:client_id)
      end

      # Q152 — aIR235B_1: Total transactions by country for purchase/sale (dimensional)
      # Type: xbrli:integerItemType — dimensional by country
      def air235b_1
        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q153 — aIR235B_2: For how many purchases/sales did you represent the buyer?
      # Type: xbrli:integerItemType — computed
      def air235b_2
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .where(agency_role: "BUYER_AGENT")
          .count
      end

      # Q154 — aIR235S: For how many purchases/sales did you represent the seller?
      # Type: xbrli:integerItemType — computed
      def air235s
        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .where(agency_role: "SELLER_AGENT")
          .count
      end

      # Q156 — aIR238B: Total value of funds transferred by client country for purchase/sale (dimensional)
      # Type: xbrli:monetaryItemType — dimensional by country
      def air238b
        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        organization.transactions.kept.for_year(year)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .sum(:transaction_value)
      end

      # Q159 — aIR2391: Has the State of Monaco pre-empted properties for sale?
      # Type: enum (Oui/Non) — settings-based
      def air2391
        setting_value_for("monaco_preempted_properties")
      end

      # Q160 — aIR2392: How many properties were pre-empted by Monaco?
      # Type: xbrli:integerItemType — settings-based, conditional on aIR2391
      def air2392
        return nil unless air2391 == "Oui"
        setting_value_for("monaco_preempted_property_count")
      end

      # Q161 — aIR2393: What was the total value of pre-empted properties?
      # Type: xbrli:monetaryItemType — settings-based, conditional on aIR2391
      def air2393
        return nil unless air2391 == "Oui"
        setting_value_for("monaco_preempted_property_value")
      end

      # Q158 — aIR117: How many purchases/sales were for investment purposes?
      # Type: xbrli:integerItemType — computed
      def air117
        organization.transactions.kept.for_year(year)
          .where(purchase_purpose: "INVESTMENT")
          .count
      end

      # Q157 — aIR239B: Total value of funds transferred by client country, 5-year lookback (dimensional)
      # Type: xbrli:monetaryItemType — dimensional by country
      def air239b
        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        five_year_range = Date.new(year - 4, 1, 1)..Date.new(year, 12, 31)

        organization.transactions.kept
          .where(transaction_date: five_year_range)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .sum(:transaction_value)
      end

      # Q155 — aIR237B: Total transactions by country for purchase/sale (5-year lookback, dimensional)
      # Type: xbrli:integerItemType — dimensional by country
      def air237b
        country_sql = "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"

        five_year_range = Date.new(year - 4, 1, 1)..Date.new(year, 12, 31)

        organization.transactions.kept
          .where(transaction_date: five_year_range)
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q162 — aIR234: Total unique properties rented in the reporting period
      # Type: xbrli:integerItemType — computed
      def air234
        organization.managed_properties.active_in_year(year).count
      end

      # Q163 — aIR236: Total rental operations in the reporting period
      # Type: xbrli:integerItemType — computed
      def air236
        organization.transactions.kept.for_year(year)
          .where(transaction_type: "RENTAL")
          .count
      end

      # Q164 — aIR2313: Unique rental properties >= 10,000 EUR/month active in reporting period
      # Type: xbrli:integerItemType — computed
      def air2313
        organization.managed_properties.active_in_year(year)
          .where("monthly_rent >= ?", 10_000)
          .count
      end

      # Q165 — aIR2316: Unique rental properties < 10,000 EUR/month active in reporting period
      # Type: xbrli:integerItemType — computed
      def air2316
        organization.managed_properties.active_in_year(year)
          .where("monthly_rent < ?", 10_000)
          .count
      end

      # Q166 — a2501A: Does entity have comments on products/services section?
      # Type: enum (Oui/Non) — settings-based
      def a2501a
        setting_value_for("has_products_services_comments")
      end
    end
  end
end
