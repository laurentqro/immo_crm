# frozen_string_literal: true

class Survey
  module Fields
    module Helpers
      private

      def setting_value_for(key)
        load_settings_cache unless @settings_cache
        @settings_cache[key]
      end

      def load_settings_cache
        @settings_cache = organization.settings.pluck(:key, :value).to_h
      end

      def year_transactions
        organization.transactions.kept.for_year(year)
      end

      def five_year_transactions
        organization.transactions.kept.where(
          transaction_date: Date.new(year - 4, 1, 1)..Date.new(year, 12, 31)
        )
      end

      def clients_kept
        organization.clients.kept
      end

      def client_country_sql
        "CASE WHEN clients.client_type = 'NATURAL_PERSON' " \
          "THEN clients.nationality ELSE clients.incorporation_country END"
      end

      def beneficial_owners_base
        BeneficialOwner
          .joins(:client)
          .merge(Client.kept)
          .where(clients: {organization_id: organization.id})
      end
    end
  end
end
