# frozen_string_literal: true

# Shared helper methods for Survey field calculations.
# Included in all field modules to provide common data access patterns.
#
# These helpers are private and should not be exposed as question IDs.
# The Survey::HELPER_METHODS constant was removed - the gem's questionnaire
# structure now defines which methods are questions vs helpers.
#
class Survey
  module Fields
    module Helpers
      extend ActiveSupport::Concern

      private

      # Base query for active clients in the organization
      def clients_kept
        organization.clients.kept
      end

      # Transactions for the reporting year
      def year_transactions
        organization.transactions.kept.for_year(year)
      end

      # Beneficial owners through the organization's clients
      def beneficial_owners_base
        BeneficialOwner.joins(:client)
          .merge(Client.kept)
          .where(clients: {organization_id: organization.id})
      end

      # Retrieve a setting value by key from the cached settings hash
      def setting_value(key)
        settings_cache[key]
      end

      # Cached hash of organization settings (key => value)
      def settings_cache
        @settings_cache ||= organization.settings
          .where.not(key: [nil, ""])
          .index_by(&:key)
          .transform_values(&:value)
      end

      # Count clients by business sector
      def clients_by_sector(sector)
        clients_kept.where(business_sector: sector).count
      end

      # Count VASP transactions by VASP type
      def vasp_transactions_by_type(vasp_type)
        year_transactions
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: vasp_type})
          .count
      end

      # Sum VASP transaction funds by VASP type
      def vasp_funds_by_type(vasp_type)
        year_transactions
          .joins(:client)
          .where(clients: {is_vasp: true, vasp_type: vasp_type})
          .sum(:transaction_value)
      end

      # Count VASP clients by country/type (scalar - deprecated)
      def vasp_clients_by_country(vasp_type)
        clients_kept
          .where(is_vasp: true, vasp_type: vasp_type)
          .where.not(incorporation_country: [nil, ""])
          .count
      end

      # VASP clients grouped by country (for dimensional fields)
      def vasp_clients_grouped_by_country(vasp_type)
        clients_kept
          .where(is_vasp: true, vasp_type: vasp_type)
          .where.not(incorporation_country: [nil, ""])
          .group(:incorporation_country)
          .count
      end
    end
  end
end
