# frozen_string_literal: true

class Survey
  module Fields
    module ProductsServicesRisk
      # Q112 — a2101W: Does entity accept or carry out cheque operations with clients?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def a2101w
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE RENTAL])
            .where(payment_method: "CHECK")
            .exists?
          "Oui"
        else
          setting_value_for("accepts_cheque_operations")
        end
      end

      # Q113 — a2101WRP: Did entity accept or carry out cheque operations during reporting period?
      # Type: enum (Oui/Non) — computed from transactions, conditional on a2101w
      def a2101wrp
        return nil unless a2101w == "Oui"

        year_transactions
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "CHECK")
          .exists? ? "Oui" : "Non"
      end

      # Q114 — a2102W: Total number of cheque operations (incoming and outgoing) with clients
      # Type: xbrli:integerItemType — computed, conditional on a2101wrp
      def a2102w
        return nil unless a2101wrp == "Oui"

        operations_count { |scope| scope.where(payment_method: "CHECK") }
      end

      # Q115 — a2102BW: Total value of cheque operations (incoming and outgoing) with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2101wrp
      def a2102bw
        return nil unless a2101wrp == "Oui"

        operations_value { |scope| scope.where(payment_method: "CHECK") }
      end

      # Q116 — a2101B: Did clients accept or perform cheque operations during reporting period?
      # Type: enum (Oui/Non) — computed from transactions
      def a2101b
        year_transactions
          .where(transaction_type: %w[PURCHASE SALE RENTAL])
          .where(payment_method: "CHECK")
          .exists? ? "Oui" : "Non"
      end

      # Q117 — a2102B: Total number of cheque operations (incoming and outgoing) by clients
      # Type: xbrli:integerItemType — computed, conditional on a2101b
      def a2102b
        return nil unless a2101b == "Oui"

        operations_count { |scope| scope.where(payment_method: "CHECK") }
      end

      # Q118 — a2102BB: Total value of cheque operations (incoming and outgoing) by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2101b
      def a2102bb
        return nil unless a2101b == "Oui"

        operations_value { |scope| scope.where(payment_method: "CHECK") }
      end

      # Q119 — a2104W: Does entity accept or make electronic wire transfers with clients?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def a2104w
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE RENTAL])
            .where(payment_method: "WIRE")
            .exists?
          "Oui"
        else
          setting_value_for("accepts_wire_transfers")
        end
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

        operations_count { |scope| scope.where(payment_method: "WIRE") }
      end

      # Q122 — a2105BW: Total value of electronic wire transfers with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2104wrp
      def a2105bw
        return nil unless a2104wrp == "Oui"

        operations_value { |scope| scope.where(payment_method: "WIRE") }
      end

      # Q123 — a2104B: Did clients accept or make electronic wire transfers in period?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def a2104b
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE RENTAL])
            .where(payment_method: "WIRE")
            .exists?
          "Oui"
        else
          setting_value_for("clients_performed_wire_transfers")
        end
      end

      # Q124 — a2105B: Total electronic wire transfer operations by clients
      # Type: xbrli:integerItemType — computed, conditional on a2104b
      def a2105b
        return nil unless a2104b == "Oui"

        operations_count { |scope| scope.where(payment_method: "WIRE") }
      end

      # Q125 — a2105BB: Total value of electronic wire transfers by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2104b
      def a2105bb
        return nil unless a2104b == "Oui"

        operations_value { |scope| scope.where(payment_method: "WIRE") }
      end

      # Q126 — a2107W: Does entity accept or carry out cash operations with clients?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def a2107w
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE RENTAL])
            .where(payment_method: %w[CASH MIXED])
            .exists?
          "Oui"
        else
          setting_value_for("accepts_cash_operations")
        end
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

        operations_count { |scope| scope.where(payment_method: %w[CASH MIXED]) }
      end

      # Q129 — a2109W: Total value of cash operations with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107wrp
      def a2109w
        return nil unless a2107wrp == "Oui"

        operations_cash_value(:cash_amount) { |scope| scope.where(payment_method: %w[CASH MIXED]) }
      end

      # Q130 — aG24010W: Total value of cash in foreign currencies with clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107wrp
      def ag24010w
        return nil unless a2107wrp == "Oui"

        operations_cash_value(:foreign_currency_cash_amount) { |scope| scope.where(payment_method: %w[CASH MIXED]) }
      end

      # Q131 — a2110W: Cash operations >= 10,000 EUR with clients
      # Type: xbrli:integerItemType — computed, conditional on a2107wrp
      def a2110w
        return nil unless a2107wrp == "Oui"

        operations_count { |scope| scope.where(payment_method: %w[CASH MIXED]).where("cash_amount >= ?", 10_000) }
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

        operations_count do |scope|
          scope.where(payment_method: %w[CASH MIXED])
            .where("cash_amount > ?", 100_000)
            .joins(:client)
            .where(clients: {client_type: "NATURAL_PERSON"})
        end
      end

      # Q134 — a2114A: Cash ops with Monegasque legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113w
      def a2114a
        return nil unless a2113w == "Oui"

        operations_count do |scope|
          scope.where(payment_method: %w[CASH MIXED])
            .where("cash_amount > ?", 100_000)
            .joins(:client)
            .where(clients: {client_type: "LEGAL_ENTITY", incorporation_country: "MC"})
        end
      end

      # Q135 — a2115AW: Cash ops with foreign legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113w
      def a2115aw
        return nil unless a2113w == "Oui"

        operations_count do |scope|
          scope.where(payment_method: %w[CASH MIXED])
            .where("cash_amount > ?", 100_000)
            .joins(:client)
            .where(clients: {client_type: "LEGAL_ENTITY"})
            .where.not(clients: {incorporation_country: "MC"})
        end
      end

      # Q136 — a2107B: Did clients perform cash operations?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def a2107b
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE RENTAL])
            .where(payment_method: %w[CASH MIXED])
            .exists?
          "Oui"
        else
          setting_value_for("clients_performed_cash_operations")
        end
      end

      # Q137 — a2108B: Total cash operations count by clients
      # Type: xbrli:integerItemType — computed, conditional on a2107b
      def a2108b
        return nil unless a2107b == "Oui"

        operations_count { |scope| scope.where(payment_method: %w[CASH MIXED]) }
      end

      # Q138 — a2109B: Total value of cash operations by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107b
      def a2109b
        return nil unless a2107b == "Oui"

        operations_cash_value(:cash_amount) { |scope| scope.where(payment_method: %w[CASH MIXED]) }
      end

      # Q139 — aG24010B: Total value of cash in foreign currencies by clients
      # Type: xbrli:monetaryItemType — computed, conditional on a2107b
      def ag24010b
        return nil unless a2107b == "Oui"

        operations_cash_value(:foreign_currency_cash_amount) { |scope| scope.where(payment_method: %w[CASH MIXED]) }
      end

      # Q140 — a2110B: Cash operations >= 10,000 EUR by clients
      # Type: xbrli:integerItemType — computed, conditional on a2107b
      def a2110b
        return nil unless a2107b == "Oui"

        operations_count { |scope| scope.where(payment_method: %w[CASH MIXED]).where("cash_amount >= ?", 10_000) }
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

        operations_count do |scope|
          scope.where(payment_method: %w[CASH MIXED])
            .where("cash_amount > ?", 100_000)
            .joins(:client)
            .where(clients: {client_type: "NATURAL_PERSON"})
        end
      end

      # Q143 — a2114AB: Cash ops by Monegasque legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113b
      def a2114ab
        return nil unless a2113b == "Oui"

        operations_count do |scope|
          scope.where(payment_method: %w[CASH MIXED])
            .where("cash_amount > ?", 100_000)
            .joins(:client)
            .where(clients: {client_type: "LEGAL_ENTITY", incorporation_country: "MC"})
        end
      end

      # Q144 — a2115AB: Cash ops by foreign legal entities > 100,000 EUR
      # Type: xbrli:integerItemType — computed, conditional on a2113b
      def a2115ab
        return nil unless a2113b == "Oui"

        operations_count do |scope|
          scope.where(payment_method: %w[CASH MIXED])
            .where("cash_amount > ?", 100_000)
            .joins(:client)
            .where(clients: {client_type: "LEGAL_ENTITY"})
            .where.not(clients: {incorporation_country: "MC"})
        end
      end

      # Q145 — a2201A: Does entity accept or conduct cryptocurrency operations with clients?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def a2201a
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE RENTAL])
            .where(payment_method: "CRYPTO")
            .exists?
          "Oui"
        else
          setting_value_for("accepts_cryptocurrency_operations")
        end
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
        country_sql = client_country_sql

        year_transactions
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
        year_transactions
          .where(transaction_type: "PURCHASE")
          .distinct
          .count(:client_id)
      end

      # Q151 — aIR233S: How many unique clients were sellers?
      # Type: xbrli:integerItemType — computed
      def air233s
        year_transactions
          .where(transaction_type: "SALE")
          .distinct
          .count(:client_id)
      end

      # Q152 — aIR235B_1: Total transactions by country for purchase/sale (dimensional)
      # Type: xbrli:integerItemType — dimensional by country
      def air235b_1
        country_sql = client_country_sql

        year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .count
      end

      # Q153 — aIR235B_2: For how many purchases/sales did you represent the buyer?
      # Type: xbrli:integerItemType — computed
      def air235b_2
        year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .where(agency_role: "BUYER_AGENT")
          .count
      end

      # Q154 — aIR235S: For how many purchases/sales did you represent the seller?
      # Type: xbrli:integerItemType — computed
      def air235s
        year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .where(agency_role: "SELLER_AGENT")
          .count
      end

      # Q156 — aIR238B: Total value of funds transferred by client country for purchase/sale (dimensional)
      # Type: xbrli:monetaryItemType — dimensional by country
      def air238b
        country_sql = client_country_sql

        year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .sum(:transaction_value)
      end

      # Q159 — aIR2391: Has the State of Monaco pre-empted properties for sale?
      # Type: enum (Oui/Non) — three-tier: evidence first, then setting fallback
      def air2391
        if year_transactions
            .where(transaction_type: %w[PURCHASE SALE])
            .where(preempted_by_state: true)
            .exists?
          "Oui"
        else
          setting_value_for("monaco_preempted_properties")
        end
      end

      # Q160 — aIR2392: How many properties were pre-empted by Monaco?
      # Type: xbrli:integerItemType — computed, conditional on aIR2391
      def air2392
        return nil unless air2391 == "Oui"

        year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .where(preempted_by_state: true)
          .count
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
        year_transactions
          .where(purchase_purpose: "INVESTMENT")
          .count
      end

      # Q157 — aIR239B: Total value of funds transferred by client country, 5-year lookback (dimensional)
      # Type: xbrli:monetaryItemType — dimensional by country
      def air239b
        country_sql = client_country_sql

        five_year_transactions
          .where(transaction_type: %w[PURCHASE SALE])
          .joins(:client)
          .where("#{country_sql} IS NOT NULL")
          .group(Arel.sql(country_sql))
          .sum(:transaction_value)
      end

      # Q155 — aIR237B: Total transactions by country for purchase/sale (5-year lookback, dimensional)
      # Type: xbrli:integerItemType — dimensional by country
      def air237b
        country_sql = client_country_sql

        five_year_transactions
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
        operations_count { |scope| scope.where(transaction_type: "RENTAL") }
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
      # Type: enum (Oui/Non)
      def a2501a
      end

      # Q167 — a2501: Products/services section comments text
      # Type: xbrli:stringItemType
      def a2501
      end
    end
  end
end
