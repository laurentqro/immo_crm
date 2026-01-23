# frozen_string_literal: true

# Tab 3: Distribution Channel Risk Assessment
# Field methods for distribution channel risk metrics
#
# Fields cover:
# - Third-party CDD (Customer Due Diligence)
# - Client introduction channels
# - Non-face-to-face relationships
# - Geographic distribution
#
class Survey
  module Fields
    module DistributionRisk
      extend ActiveSupport::Concern

      private

      # === Third-Party CDD ===

      def uses_local_third_party_cdd
        setting_value("uses_local_third_party_cdd") || "Non"
      end

      def uses_foreign_third_party_cdd
        setting_value("uses_foreign_third_party_cdd") || "Non"
      end

      def uses_third_party_cdd
        (uses_local_third_party_cdd == "Oui" || uses_foreign_third_party_cdd == "Oui") ? "Oui" : "Non"
      end

      def third_party_cdd_difficulties
        setting_value("third_party_cdd_difficulties") || "Non"
      end

      def third_party_difficulty_reasons
        setting_value("third_party_difficulty_reasons")
      end

      # Third-party CDD clients by nationality
      def local_third_party_clients_by_nationality
        # Would need tracking of third-party CDD clients - return 0 for now
        0
      end

      def foreign_third_party_clients_by_nationality
        0
      end

      def foreign_third_party_by_residence
        0
      end

      # === Client Introduction Channels ===

      def accepts_clients_via_introducers
        setting_value("accepts_clients_via_introducers") || "Non"
      end

      def introduced_clients_by_nationality
        # Would need introducer tracking - return 0 for now
        0
      end

      def introduced_clients_period_by_nationality
        0
      end

      def introduced_clients_by_introducer_residence
        0
      end

      def introduced_clients_period_by_introducer
        0
      end

      # === Non-Face-to-Face Relationships ===

      def accepts_non_face_to_face
        setting_value("accepts_non_face_to_face") || "Non"
      end

      # Non-face-to-face for trusts
      def non_face_to_face_trusts
        # Would need tracking of non-f2f trust relationships - return 0
        0
      end

      def non_face_to_face_trusts_by_country
        0
      end

      def non_face_to_face_trusts_period
        0
      end

      def non_face_to_face_trusts_by_trust_country
        0
      end

      # Non-face-to-face for legal entities
      def non_face_to_face_legal_entities
        setting_value("non_face_to_face_legal_entities") || "Non"
      end

      def non_face_to_face_legal_entities_period
        setting_value("non_face_to_face_legal_entities_period")
      end

      # Non-face-to-face by nationality
      def non_face_to_face_by_nationality
        setting_value("non_face_to_face_by_nationality") || "Non"
      end

      def non_face_to_face_period
        setting_value("non_face_to_face_period")
      end

      # === Risk Assessment ===

      def has_country_risk_assessment
        setting_value("has_country_risk_assessment") || "Oui"
      end

      def risk_assessment_methodology
        setting_value("risk_assessment_methodology") || "Non"
      end

      # === Acquisition and Marketing Channels ===

      def acquisition_channels
        setting_value("acquisition_channels") || "Non"
      end

      def marketing_channels
        setting_value("marketing_channels") || "Non"
      end

      def online_presence
        setting_value("online_presence") || "Non"
      end

      def virtual_showings
        setting_value("virtual_showings") || "Non"
      end

      def referral_arrangements
        setting_value("referral_arrangements")
      end

      # === Geographic Scope ===

      def geographic_scope
        setting_value("geographic_scope")
      end
    end
  end
end
