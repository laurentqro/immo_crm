# frozen_string_literal: true

# Tab 5: Signatories
# Field methods for signatory information and entity details
#
# Fields cover:
# - Entity information (legal form, registration)
# - Business profile (services, revenue)
# - Office locations
# - Employee information
# - Submission status
#
class Survey
  module Fields
    module Signatories
      extend ActiveSupport::Concern

      private

      # === Entity Information ===

      def legal_form
        setting_value("legal_form")&.to_i || 0
      end

      def registration_number
        setting_value("registration_number")&.to_i || 0
      end

      def registration_date
        setting_value("registration_date")
      end

      # === Business Profile ===

      def primary_activity
        setting_value("primary_activity") || "Non"
      end

      def other_services
        setting_value("other_services") || "Non"
      end

      # Services offered
      def escrow_services
        setting_value("escrow_services") || "Non"
      end

      def escrow_volume
        setting_value("escrow_volume") || "Non"
      end

      def property_management
        setting_value("property_management") || "Non"
      end

      def ancillary_services
        setting_value("ancillary_services")
      end

      def insurance_services
        setting_value("insurance_services") || "Non"
      end

      def mortgage_services
        setting_value("mortgage_services") || "Non"
      end

      def valuation_services
        setting_value("valuation_services") || "Non"
      end

      def legal_services
        setting_value("legal_services")
      end

      def renovation_services
        setting_value("renovation_services") || "Non"
      end

      # === Financial Information ===

      def annual_revenue
        setting_value("annual_revenue")&.to_i || 0
      end

      def real_estate_revenue
        setting_value("real_estate_revenue")&.to_i || 0
      end

      def operating_expenses
        setting_value("operating_expenses") || "Non"
      end

      def avg_transaction_size
        setting_value("avg_transaction_size") || "Non"
      end

      def annual_transaction_volume
        setting_value("annual_transaction_volume") || "Non"
      end

      # === Market Information ===

      def residential_vs_commercial
        setting_value("residential_vs_commercial") || "Non"
      end

      def market_segments
        setting_value("market_segments")&.to_i || 0
      end

      def luxury_percentage
        setting_value("luxury_percentage") || "Non"
      end

      def new_vs_existing_property
        setting_value("new_vs_existing_property") || "Non"
      end

      # === Office Information ===

      def offices_count
        setting_value("offices_count") || "Non"
      end

      def monaco_offices
        setting_value("monaco_offices")
      end

      def overseas_offices
        setting_value("overseas_offices") || "Non"
      end

      # === Employee Information ===

      def employee_count
        setting_value("employee_count")
      end

      def licensed_agents
        setting_value("licensed_agents") || "Non"
      end

      def fiscal_year_end
        setting_value("fiscal_year_end") || "Decembre"
      end

      # === Submission Status ===

      def status_1
        setting_value("status_1")
      end

      def status_2
        setting_value("status_2")
      end

      def survey_incomplete
        setting_value("survey_incomplete")
      end

      # === Legal Entity Status ===

      def legal_entity_status
        clients_kept.legal_entities.count
      end
    end
  end
end
