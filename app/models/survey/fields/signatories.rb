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

      # C67: Total clients with enhanced due diligence (EDD) at onboarding
      # Counts clients with REINFORCED DD level who became clients during the reporting year
      def ac1701
        clients_kept
          .where(due_diligence_level: "REINFORCED")
          .where(became_client_at: Date.new(year, 1, 1)..Date.new(year, 12, 31))
          .count
      end

      # C68: Total clients with enhanced due diligence during relationship
      # All clients currently with REINFORCED DD level (reviewed during the period)
      def ac1702
        clients_kept
          .where(due_diligence_level: "REINFORCED")
          .count
      end

      # C69: Percentage of clients with enhanced due diligence
      # i.e. number of enhanced due diligence clients / total number of clients
      def ac1703
        total = clients_kept.count
        return 0 if total.zero?

        reinforced = clients_kept.where(due_diligence_level: "REINFORCED").count
        (reinforced.to_f / total * 100).round(2)
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

      # Total unique clients (repeat of a1101)
      def ac1611
        organization.clients.count
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

      # Q37: Monaco legal entity clients grouped by legal_entity_type
      # Returns dimensional hash of type label => count for MC-incorporated legal entities
      def amles
        clients_kept
          .legal_entities
          .where(incorporation_country: "MC")
          .where.not(legal_entity_type: [nil, ""])
          .group(:legal_entity_type)
          .count
      end
    end
  end
end
