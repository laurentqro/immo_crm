# frozen_string_literal: true

module Clients
  # Assesses a client's risk factors and returns a structured risk assessment.
  # Does NOT auto-update the client's risk_level -- that requires human sign-off.
  #
  # Usage:
  #   assessment = Clients::AssessRisk.call(client: client)
  #   assessment.record  # => { suggested_level: "HIGH", factors: [...], current_level: "LOW" }
  #
  class AssessRisk
    RISK_FACTORS = {
      pep: { weight: :high, description: "Client is a Politically Exposed Person" },
      pep_related: { weight: :high, description: "Client is related to a PEP" },
      pep_associated: { weight: :high, description: "Client is associated with a PEP" },
      vasp: { weight: :high, description: "Client is a Virtual Asset Service Provider" },
      high_risk_country: { weight: :high, description: "Client from high-risk jurisdiction" },
      non_resident: { weight: :medium, description: "Client is a non-resident" },
      complex_structure: { weight: :medium, description: "Trust or complex legal structure" },
      cash_transactions: { weight: :medium, description: "Client has cash transactions" },
      beneficial_owner_pep: { weight: :high, description: "Beneficial owner is a PEP" },
      str_filed: { weight: :high, description: "Suspicious transaction report filed" }
    }.freeze

    # FATF high-risk jurisdictions (simplified - should be configurable)
    HIGH_RISK_COUNTRIES = %w[AF KP IR MM SY YE].freeze

    def self.call(client:)
      new(client: client).call
    end

    def initialize(client:)
      @client = client
    end

    def call
      factors = detect_factors
      suggested_level = calculate_level(factors)

      assessment = {
        client_id: @client.id,
        current_level: @client.risk_level,
        suggested_level: suggested_level,
        factors: factors,
        requires_change: @client.risk_level != suggested_level,
        assessed_at: Time.current
      }

      ServiceResult.success(assessment)
    end

    private

    def detect_factors
      factors = []
      factors << factor(:pep) if @client.is_pep?
      factors << factor(:pep_related) if @client.is_pep_related?
      factors << factor(:pep_associated) if @client.is_pep_associated?
      factors << factor(:vasp) if @client.is_vasp?

      if @client.nationality.present? && HIGH_RISK_COUNTRIES.include?(@client.nationality)
        factors << factor(:high_risk_country)
      end

      factors << factor(:non_resident) if @client.residence_status == "NON_RESIDENT"
      factors << factor(:complex_structure) if @client.trust?
      factors << factor(:cash_transactions) if @client.transactions.with_cash.exists?
      factors << factor(:beneficial_owner_pep) if @client.beneficial_owners.peps.exists?
      factors << factor(:str_filed) if @client.str_reports.exists?

      factors
    end

    def factor(key)
      config = RISK_FACTORS[key]
      { key: key, weight: config[:weight], description: config[:description] }
    end

    def calculate_level(factors)
      return "HIGH" if factors.any? { |f| f[:weight] == :high }
      return "MEDIUM" if factors.any? { |f| f[:weight] == :medium }
      "LOW"
    end
  end
end
