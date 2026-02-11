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

      # Transactions for the reporting year and 4 previous years (5-year lookback)
      def five_year_transactions
        organization.transactions.kept
          .where("transaction_date >= ?", Date.new(year - 4, 1, 1))
          .where("transaction_date <= ?", Date.new(year, 12, 31))
      end

      # Group purchase/sale transactions by client nationality or incorporation country.
      # Returns a hash of { country_code => count_or_sum }.
      # Natural persons use nationality, legal entities use incorporation_country.
      def transactions_by_client_country(transactions_scope, aggregate: :count)
        natural = transactions_scope
          .joins(:client)
          .merge(Client.kept.natural_persons)
          .where.not(clients: {nationality: [nil, ""]})
          .group("clients.nationality")

        legal = transactions_scope
          .joins(:client)
          .merge(Client.kept.legal_entities)
          .where.not(clients: {incorporation_country: [nil, ""]})
          .group("clients.incorporation_country")

        natural_result = (aggregate == :sum) ? natural.sum(:transaction_value) : natural.count
        legal_result = (aggregate == :sum) ? legal.sum(:transaction_value) : legal.count

        natural_result.merge(legal_result) { |_key, v1, v2| v1 + v2 }
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

      # VASP clients NOT in AMSF named types, grouped by country (for "other" bucket)
      def vasp_clients_grouped_by_country_other
        clients_kept
          .where(is_vasp: true)
          .where.not(vasp_type: AmsfConstants::AMSF_NAMED_VASP_TYPES)
          .where.not(incorporation_country: [nil, ""])
          .group(:incorporation_country)
          .count
      end

      # VASP transactions NOT in AMSF named types
      def vasp_transactions_by_type_other
        year_transactions
          .joins(:client)
          .where(clients: {is_vasp: true})
          .where.not(clients: {vasp_type: AmsfConstants::AMSF_NAMED_VASP_TYPES})
          .count
      end

      # VASP funds NOT in AMSF named types
      def vasp_funds_by_type_other
        year_transactions
          .joins(:client)
          .where(clients: {is_vasp: true})
          .where.not(clients: {vasp_type: AmsfConstants::AMSF_NAMED_VASP_TYPES})
          .sum(:transaction_value)
      end
    end
  end
end
