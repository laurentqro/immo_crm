# frozen_string_literal: true

# Tab 4: Internal Controls
# Field methods for internal control measures
#
# Fields cover:
# - Staff training
# - Compliance function
# - Due diligence procedures (simplified, enhanced)
# - AML/CFT policies
# - Transaction monitoring
# - Sanctions screening
# - SAR (Suspicious Activity Reports) filing
# - Record keeping
# - Audit procedures
#
class Survey
  module Fields
    module Controls
      extend ActiveSupport::Concern

      private

      # === Training ===

      def staff_trained
        organization.trainings.for_year(year).sum(:staff_count)
      end

      def training_frequency
        setting_value("training_frequency")&.to_i || 1
      end

      def provides_aml_training
        organization.trainings.for_year(year).exists? ? "Oui" : "Non"
      end

      # === Compliance Function ===

      def compliance_fte
        setting_value("compliance_fte")&.to_d || 0
      end

      def has_compliance_officer
        setting_value("has_compliance_officer")&.to_d || 0
      end

      def compliance_officer_role
        setting_value("compliance_officer_role")&.to_d || 0
      end

      def compliance_officer_reporting
        setting_value("compliance_officer_reporting")&.to_d || 0
      end

      # === Due Diligence Procedures ===

      # Legal form of the entity
      def quelle_est_la_forme_juridique_de_entity
        setting_value("quelle_est_la_forme_juridique_de_entity") || "SAM"
      end

      # Simplified due diligence
      def uses_simplified_dd
        clients_kept.where(due_diligence_level: "SIMPLIFIED").count
      end

      def ir_328
        uses_simplified_dd.positive? ? "Oui" : "Non"
      end

      def simplified_dd_clients
        uses_simplified_dd.positive? ? "Oui" : "Non"
      end

      def simplified_dd_new_clients
        # New clients with simplified DD in the year
        clients_kept
          .where(due_diligence_level: "SIMPLIFIED")
          .where("became_client_at >= ?", Date.new(year, 1, 1))
          .where("became_client_at <= ?", Date.new(year, 12, 31))
          .count
      end

      # Enhanced due diligence
      def uses_enhanced_dd
        clients_kept.where(due_diligence_level: "REINFORCED").exists? ? "Oui" : "Non"
      end

      def enhanced_dd_clients
        clients_kept.where(due_diligence_level: "REINFORCED").exists? ? "Oui" : "Non"
      end

      def enhanced_dd_new_clients
        # Enum value for how many new clients got enhanced DD
        count = clients_kept
          .where(due_diligence_level: "REINFORCED")
          .where("became_client_at >= ?", Date.new(year, 1, 1))
          .where("became_client_at <= ?", Date.new(year, 12, 31))
          .count

        case count
        when 0 then "Aucun"
        when 1..5 then "1-5"
        when 6..10 then "6-10"
        else "Plus de 10"
        end
      end

      def enhanced_dd_legal_entities
        clients_kept
          .legal_entities
          .where(due_diligence_level: "REINFORCED")
          .exists? ? "Oui" : "Non"
      end

      def enhanced_dd_trusts
        setting_value("enhanced_dd_trusts")
      end

      def enhanced_dd_individuals_by_residence
        setting_value("enhanced_dd_individuals_by_residence")
      end

      def enhanced_dd_by_country_residence
        clients_kept
          .where(due_diligence_level: "REINFORCED")
          .where.not(residence_country: [nil, ""])
          .count
      end

      def enhanced_dd_individuals_by_nationality
        clients_kept
          .natural_persons
          .where(due_diligence_level: "REINFORCED")
          .where.not(nationality: [nil, ""])
          .count
      end

      # CDD refresh
      def cdd_refresh_frequency
        setting_value("cdd_refresh_frequency")&.to_i || 12
      end

      def has_event_driven_refresh
        setting_value("has_event_driven_refresh") || "Oui"
      end

      def has_risk_based_refresh
        setting_value("has_risk_based_refresh")&.to_i || 0
      end

      def clients_reviewed_enhanced_dd
        # Clients reviewed with enhanced DD during period
        0
      end

      def clients_with_cdd_gaps
        setting_value("clients_with_cdd_gaps") || "Non"
      end

      def cdd_gaps_percentage
        setting_value("cdd_gaps_percentage")&.to_i || 0
      end

      # === Risk Scoring ===

      def has_client_risk_scoring
        setting_value("has_client_risk_scoring")
      end

      def risk_scoring_methodology
        setting_value("risk_scoring_methodology") || "Non"
      end

      # === ID Verification and Records ===

      def enhanced_id_verification
        setting_value("enhanced_id_verification") || "Oui"
      end

      def examines_source_of_wealth
        setting_value("examines_source_of_wealth") || "Oui"
      end

      def records_id_card
        setting_value("records_id_card") || "Oui"
      end

      def records_passport
        setting_value("records_passport") || "Oui"
      end

      def records_residence_permit
        setting_value("records_residence_permit") || "Oui"
      end

      def records_other_id
        setting_value("records_other_id") || "Non"
      end

      # === High-Risk CDD Frequency ===

      def high_risk_sales_cdd_frequency
        setting_value("high_risk_sales_cdd_frequency") || "A chaque transaction"
      end

      def high_risk_rental_cdd_frequency
        setting_value("high_risk_rental_cdd_frequency") || "Annuellement"
      end

      def high_risk_additional_measures
        setting_value("high_risk_additional_measures") || "Oui"
      end

      def high_risk_measures_details
        setting_value("high_risk_measures_details")
      end

      # === SAR (Suspicious Activity Reports) ===

      def sar_filed_period
        year_start = Date.new(year, 1, 1)
        year_end = Date.new(year, 12, 31)

        organization.str_reports.kept
          .where(report_date: year_start..year_end)
          .count
      end

      def sar_filed
        setting_value("sar_filed")
      end

      def detected_suspicious_activity
        setting_value("detected_suspicious_activity")
      end

      # SAR breakdowns
      def sar_individuals_by_nationality
        setting_value("sar_individuals_by_nationality") || "Non"
      end

      def sar_legal_entities
        setting_value("sar_legal_entities") || "Non"
      end

      def sar_trusts
        setting_value("sar_trusts") || "Non"
      end

      def sar_predicate_offenses
        setting_value("sar_predicate_offenses") || "Non"
      end

      def sar_red_flags
        setting_value("sar_red_flags") || "Non"
      end

      # === Sanctions Screening ===

      def performs_sanctions_screening
        setting_value("performs_sanctions_screening") || "Oui"
      end

      def sanctions_screening_frequency
        setting_value("sanctions_screening_frequency") || "Oui"
      end

      def sanctions_coverage
        setting_value("sanctions_coverage") || "Oui"
      end

      def sanctions_hits
        setting_value("sanctions_hits")
      end

      # === Transaction Monitoring ===

      def uses_transaction_monitoring
        setting_value("uses_transaction_monitoring") || "Non"
      end

      def monitoring_system
        setting_value("monitoring_system")&.to_i || 0
      end

      def monitoring_alerts
        setting_value("monitoring_alerts")&.to_i || 0
      end

      def alerts_escalated
        setting_value("alerts_escalated") || "Non"
      end

      # === SICCFIN Requests ===

      def siccfin_requests
        setting_value("siccfin_requests") || "Non"
      end

      # === AML System and Software ===

      def uses_aml_software
        setting_value("uses_aml_software") || "Non"
      end

      def software_vendor
        setting_value("software_vendor") || "Non"
      end

      def system_capabilities
        setting_value("system_capabilities")&.to_i || 0
      end

      def system_last_upgraded
        setting_value("system_last_upgraded") || "Non"
      end

      # === AML Policy ===

      def has_aml_policy
        setting_value("has_aml_policy") || "Oui"
      end

      def policy_last_updated
        setting_value("policy_last_updated") || "Oui"
      end

      def policy_board_approved
        setting_value("policy_board_approved") || "Oui"
      end

      def policy_covers_cdd
        setting_value("policy_covers_cdd") || "Oui"
      end

      def policy_covers_monitoring
        setting_value("policy_covers_monitoring") || "Oui"
      end

      def policy_covers_sar
        setting_value("policy_covers_sar")
      end

      def policy_covers_sanctions
        setting_value("policy_covers_sanctions") || "Oui"
      end

      def policy_covers_risk
        setting_value("policy_covers_risk") || "Oui"
      end

      def policy_covers_third_parties
        setting_value("policy_covers_third_parties") || "Non"
      end

      def policy_covers_records
        setting_value("policy_covers_records") || "Oui"
      end

      def policy_covers_training
        setting_value("policy_covers_training") || "Oui"
      end

      # === Board and Management ===

      def board_oversight
        setting_value("board_oversight") || "Oui"
      end

      def board_reporting_frequency
        setting_value("board_reporting_frequency") || "Oui"
      end

      def senior_management_involved
        setting_value("senior_management_involved") || "Oui"
      end

      def aml_budget_allocated
        setting_value("aml_budget_allocated") || "Oui"
      end

      # === Staff ===

      def aml_staff
        setting_value("aml_staff") || "Non"
      end

      def staff_qualifications
        setting_value("staff_qualifications")&.to_i || 0
      end

      def staff_turnover
        setting_value("staff_turnover")
      end

      # === Record Retention ===

      def retention_years
        setting_value("retention_years") || "Oui"
      end

      def record_retention_policy
        setting_value("record_retention_policy")
      end

      # === Audit ===

      def has_internal_audit
        setting_value("has_internal_audit") || "Non"
      end

      def audit_frequency
        setting_value("audit_frequency") || "Non"
      end

      def external_audit_performed
        setting_value("external_audit_performed") || "Non"
      end

      def audit_findings
        setting_value("audit_findings")
      end

      def findings_remediated
        setting_value("findings_remediated")
      end

      def audit_methodology
        setting_value("audit_methodology") || "Non"
      end

      def audit_scope
        setting_value("audit_scope") || "Non"
      end

      def audit_independence
        setting_value("audit_independence") || "Non"
      end

      def audit_reporting
        setting_value("audit_reporting") || "Non"
      end

      # === Group Information Sharing ===

      def part_of_group
        setting_value("part_of_group")&.to_i || 0
      end

      def group_policy_applies
        setting_value("group_policy_applies")&.to_i || 0
      end

      def group_info_sharing
        setting_value("group_info_sharing") || "Non"
      end
    end
  end
end
