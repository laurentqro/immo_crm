# frozen_string_literal: true

module Compliance
  # Generates an organization-wide risk assessment summary.
  # Aggregates client risk data for compliance reporting.
  #
  # Usage:
  #   result = Compliance::RiskAssessment.call(organization: org, year: 2025)
  #   result.record  # => { clients: { total: 100, high: 5, ... }, transactions: {...} }
  #
  class RiskAssessment
    def self.call(organization:, year: Date.current.year)
      new(organization: organization, year: year).call
    end

    def initialize(organization:, year:)
      @organization = organization
      @year = year
    end

    def call
      data = {
        organization_id: @organization.id,
        year: @year,
        assessed_at: Time.current,
        clients: client_summary,
        transactions: transaction_summary,
        str_reports: str_summary,
        beneficial_owners: beneficial_owner_summary
      }

      ServiceResult.success(data)
    end

    private

    def clients
      @clients ||= @organization.clients.kept
    end

    def client_summary
      {
        total: clients.count,
        by_risk_level: {
          high: clients.high_risk.count,
          medium: clients.where(risk_level: "MEDIUM").count,
          low: clients.where(risk_level: "LOW").count,
          unassessed: clients.where(risk_level: [nil, ""]).count
        },
        by_type: {
          natural_persons: clients.natural_persons.count,
          legal_entities: clients.legal_entities.count,
          trusts: clients.trusts.count
        },
        peps: clients.peps.count,
        vasps: clients.vasps.count,
        non_residents: clients.non_residents.count,
        active: clients.active.count,
        ended: clients.ended.count
      }
    end

    def transaction_summary
      txns = @organization.transactions.kept.for_year(@year)
      {
        total: txns.count,
        by_type: {
          purchases: txns.purchases.count,
          sales: txns.sales.count,
          rentals: txns.rentals.count
        },
        with_cash: txns.with_cash.count,
        total_value: txns.sum(:transaction_value),
        total_cash: txns.sum(:cash_amount)
      }
    end

    def str_summary
      strs = @organization.str_reports.kept.for_year(@year)
      {
        total: strs.count,
        by_reason: {
          cash: strs.by_reason("CASH").count,
          pep: strs.by_reason("PEP").count,
          unusual_pattern: strs.by_reason("UNUSUAL_PATTERN").count,
          other: strs.by_reason("OTHER").count
        }
      }
    end

    def beneficial_owner_summary
      owners = BeneficialOwner.joins(:client).where(clients: { organization_id: @organization.id })
      {
        total: owners.count,
        peps: owners.peps.count,
        hnwis: owners.hnwis.count,
        uhnwis: owners.uhnwis.count
      }
    end
  end
end
