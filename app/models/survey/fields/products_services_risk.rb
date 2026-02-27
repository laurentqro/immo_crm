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
    end
  end
end
