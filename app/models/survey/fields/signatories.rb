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
      include Helpers

      private

      # === Entity Information ===

      def ac1701
        setting_value("legal_form")&.to_i || 0
      end

      def ac1702
        setting_value("registration_number")&.to_i || 0
      end

      def ac1703
        setting_value("registration_date")
      end

      # === Business Profile ===

      def ac1601
        setting_value("primary_activity") || "Non"
      end

      def ac168
        setting_value("other_services") || "Non"
      end

      # Services offered
      def ac1635
        setting_value("escrow_services") || "Non"
      end

      def ac1635a
        setting_value("escrow_volume") || "Non"
      end

      def ac1636
        setting_value("property_management") || "Non"
      end

      def ac1637
        setting_value("ancillary_services")
      end

      def ac1638a
        setting_value("insurance_services") || "Non"
      end

      def ac1639a
        setting_value("mortgage_services") || "Non"
      end

      def ac1641a
        setting_value("valuation_services") || "Non"
      end

      def ac1640a
        setting_value("legal_services")
      end

      def ac1642a
        setting_value("renovation_services") || "Non"
      end

      # === Financial Information ===

      def ac1801
        setting_value("annual_revenue")&.to_i || 0
      end

      # C51: Total unique clients (repeat of a1101 — uses clients_kept scope)
      def ac1611
        clients_kept.count
      end

      # High-risk clients count
      def ac1802
        clients_kept.where(risk_level: "high").count
      end

      def ac1806
        setting_value("operating_expenses") || "Non"
      end

      def ac1609
        setting_value("avg_transaction_size") || "Non"
      end

      def ac1610
        setting_value("annual_transaction_volume") || "Non"
      end

      # === Market Information ===

      def ac1612a
        setting_value("residential_vs_commercial") || "Non"
      end

      def ac1612
        setting_value("market_segments")&.to_i || 0
      end

      def ac1614
        setting_value("luxury_percentage") || "Non"
      end

      def ac1615
        setting_value("new_vs_existing_property") || "Non"
      end

      # === Office Information ===

      def ac1812
        setting_value("offices_count") || "Non"
      end

      def ac1813
        setting_value("monaco_offices")
      end

      def ac1814w
        setting_value("overseas_offices") || "Non"
      end

      # === Employee Information ===

      def ac1807
        setting_value("employee_count")
      end

      def ac1811
        setting_value("licensed_agents") || "Non"
      end

      def ac1904
        setting_value("last_external_audit")
      end

      # === Submission Status ===

      def as1
        setting_value("status_1")
      end

      def as2
        setting_value("status_2")
      end

      def aincomplete
        setting_value("survey_incomplete")
      end

      # === Legal Entity Status ===

      def amles
        clients_kept.legal_entities.count
      end
    end
  end
end
