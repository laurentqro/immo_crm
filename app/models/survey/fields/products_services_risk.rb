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
    end
  end
end
