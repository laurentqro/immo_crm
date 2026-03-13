# frozen_string_literal: true

module Transactions
  # Screens a transaction against AML red flags.
  # Returns risk indicators without blocking the transaction.
  #
  # Usage:
  #   result = Transactions::Screen.call(transaction: txn)
  #   result.record  # => { flags: [...], risk_score: "HIGH", recommend_str: true }
  #
  class Screen
    # Screening thresholds
    CASH_THRESHOLD = 10_000 # EUR - FATF threshold
    HIGH_VALUE_THRESHOLD = 1_000_000 # EUR

    def self.call(transaction:)
      new(transaction: transaction).call
    end

    def initialize(transaction:)
      @transaction = transaction
    end

    def call
      flags = detect_flags
      risk_score = calculate_risk(flags)

      screening = {
        transaction_id: @transaction.id,
        flags: flags,
        risk_score: risk_score,
        recommend_str: risk_score == "HIGH",
        screened_at: Time.current
      }

      ServiceResult.success(screening)
    end

    private

    def detect_flags
      flags = []
      flags << cash_flag if cash_above_threshold?
      flags << high_value_flag if high_value?
      flags << pep_flag if client_is_pep?
      flags << crypto_flag if crypto_payment?
      flags << high_risk_client_flag if high_risk_client?
      flags
    end

    def cash_above_threshold?
      @transaction.cash_amount.present? && @transaction.cash_amount >= CASH_THRESHOLD
    end

    def high_value?
      @transaction.transaction_value.present? && @transaction.transaction_value >= HIGH_VALUE_THRESHOLD
    end

    def client_is_pep?
      @transaction.client&.is_pep?
    end

    def crypto_payment?
      @transaction.payment_method == "CRYPTO"
    end

    def high_risk_client?
      @transaction.client&.risk_level == "HIGH"
    end

    def cash_flag
      { key: :cash_threshold, severity: :high,
        description: "Cash amount (#{@transaction.cash_amount} EUR) exceeds #{CASH_THRESHOLD} EUR threshold" }
    end

    def high_value_flag
      { key: :high_value, severity: :medium,
        description: "Transaction value (#{@transaction.transaction_value} EUR) exceeds #{HIGH_VALUE_THRESHOLD} EUR" }
    end

    def pep_flag
      { key: :pep_involved, severity: :high,
        description: "Client is a Politically Exposed Person (#{@transaction.client.pep_type})" }
    end

    def crypto_flag
      { key: :crypto_payment, severity: :medium,
        description: "Transaction uses cryptocurrency payment" }
    end

    def high_risk_client_flag
      { key: :high_risk_client, severity: :high,
        description: "Client is classified as high risk" }
    end

    def calculate_risk(flags)
      return "HIGH" if flags.any? { |f| f[:severity] == :high }
      return "MEDIUM" if flags.any? { |f| f[:severity] == :medium }
      "LOW"
    end
  end
end
