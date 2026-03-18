# frozen_string_literal: true

class Survey
  module Fields
    module Helpers
      private

      def setting_value_for(key)
        load_settings_cache unless @settings_cache
        value = @settings_cache[key]
        value = normalize_boolean(value)
        value.presence
      end

      def load_settings_cache
        @settings_cache = organization.settings.pluck(:key, :value).to_h
      end

      def normalize_boolean(value)
        case value
        when "true" then "Oui"
        when "false" then "Non"
        else value
        end
      end

      def year_transactions
        organization.transactions.kept.for_year(year)
      end

      def year_rentals
        organization.transactions.kept.rentals_active_in_year(year)
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

      def operations_count(&filter)
        filter.call(year_transactions).where.not(transaction_type: "RENTAL").count +
          filter.call(year_rentals).sum { |t| t.transaction_count_in_year(year) }
      end

      def operations_value(&filter)
        filter.call(year_transactions).where.not(transaction_type: "RENTAL").sum(:transaction_value) +
          filter.call(year_rentals).sum { |t| t.monthly_value * t.transaction_count_in_year(year) }
      end

      def operations_cash_value(column, &filter)
        filter.call(year_transactions).where.not(transaction_type: "RENTAL").sum(column) +
          filter.call(year_rentals).sum { |t| (t.send(column) || 0) * t.transaction_count_in_year(year) }
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
