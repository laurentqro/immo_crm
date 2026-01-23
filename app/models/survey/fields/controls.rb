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

      def ab3206
        organization.trainings.for_year(year).sum(:staff_count)
      end

      def ab3207
        setting_value("ab3207")&.to_i || 1
      end

      def ab1801b
        organization.trainings.for_year(year).exists? ? "Oui" : "Non"
      end

      # === Compliance Function ===

      def a381
        setting_value("a381")&.to_d || 0
      end

      def a3802
        setting_value("a3802")&.to_d || 0
      end

      def a3803
        setting_value("a3803")&.to_d || 0
      end

      def a3804
        setting_value("a3804")&.to_d || 0
      end

      # === Due Diligence Procedures ===

      # Legal form of the entity
      def air33lf
        setting_value("air33lf") || "SAM"
      end

      # Simplified due diligence
      def a3301
        clients_kept.where(due_diligence_level: "SIMPLIFIED").count
      end

      def air328
        a3301.positive? ? "Oui" : "Non"
      end

      def a3302
        a3301.positive? ? "Oui" : "Non"
      end

      def a3303
        # New clients with simplified DD in the year
        clients_kept
          .where(due_diligence_level: "SIMPLIFIED")
          .where("became_client_at >= ?", Date.new(year, 1, 1))
          .where("became_client_at <= ?", Date.new(year, 12, 31))
          .count
      end

      # Enhanced due diligence
      def a3304
        clients_kept.where(due_diligence_level: "REINFORCED").exists? ? "Oui" : "Non"
      end

      def a3304c
        clients_kept.where(due_diligence_level: "REINFORCED").exists? ? "Oui" : "Non"
      end

      def a3305
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

      def a3307
        clients_kept
          .legal_entities
          .where(due_diligence_level: "REINFORCED")
          .exists? ? "Oui" : "Non"
      end

      def a3308
        setting_value("a3308")
      end

      def a3306a
        setting_value("a3306a")
      end

      def a3306b
        clients_kept
          .where(due_diligence_level: "REINFORCED")
          .where.not(residence_country: [nil, ""])
          .count
      end

      def a3306
        clients_kept
          .natural_persons
          .where(due_diligence_level: "REINFORCED")
          .where.not(nationality: [nil, ""])
          .count
      end

      # CDD refresh
      def a3401
        setting_value("a3401")&.to_i || 12
      end

      def a3402
        setting_value("a3402") || "Oui"
      end

      def a3403
        setting_value("a3403")&.to_i || 0
      end

      def a3414
        # Clients reviewed with enhanced DD during period
        0
      end

      def a3415
        setting_value("a3415") || "Non"
      end

      def a3416
        setting_value("a3416")&.to_i || 0
      end

      # === Risk Scoring ===

      def a3701
        setting_value("a3701")
      end

      def a3701a
        setting_value("a3701a") || "Non"
      end

      # === ID Verification and Records ===

      def ac1620
        setting_value("ac1620") || "Oui"
      end

      def ac1617
        setting_value("ac1617") || "Oui"
      end

      def ac1625
        setting_value("ac1625") || "Oui"
      end

      def ac1626
        setting_value("ac1626") || "Oui"
      end

      def ac1627
        setting_value("ac1627") || "Oui"
      end

      def ac1629
        setting_value("ac1629") || "Non"
      end

      # === High-Risk CDD Frequency ===

      def ac1616b
        setting_value("ac1616b") || "A chaque transaction"
      end

      def ac1616a
        setting_value("ac1616a") || "Annuellement"
      end

      def ac1618
        setting_value("ac1618") || "Oui"
      end

      def ac1619
        setting_value("ac1619")
      end

      # === SAR (Suspicious Activity Reports) ===

      def ac1102a
        year_start = Date.new(year, 1, 1)
        year_end = Date.new(year, 12, 31)

        organization.str_reports.kept
          .where(report_date: year_start..year_end)
          .count
      end

      def ac1102
        setting_value("ac1102")
      end

      def ac1101z
        setting_value("ac1101z")
      end

      # SAR breakdowns
      def ac11101
        setting_value("ac11101") || "Non"
      end

      def ac11102
        setting_value("ac11102") || "Non"
      end

      def ac11103
        setting_value("ac11103") || "Non"
      end

      def ac11104
        setting_value("ac11104") || "Non"
      end

      def ac11105
        setting_value("ac11105") || "Non"
      end

      # === Sanctions Screening ===

      def ac114
        setting_value("ac114") || "Oui"
      end

      def ac11401
        setting_value("ac11401") || "Oui"
      end

      def ac11402
        setting_value("ac11402") || "Oui"
      end

      def ac11403
        setting_value("ac11403")
      end

      # === Transaction Monitoring ===

      def ac11501b
        setting_value("ac11501b") || "Non"
      end

      def ac11502
        setting_value("ac11502")&.to_i || 0
      end

      def ac11504
        setting_value("ac11504")&.to_i || 0
      end

      def ac11508
        setting_value("ac11508") || "Non"
      end

      # === SICCFIN Requests ===

      def ac1106
        setting_value("ac1106") || "Non"
      end

      # === AML System and Software ===

      def ac1501
        setting_value("ac1501") || "Non"
      end

      def ac1503b
        setting_value("ac1503b") || "Non"
      end

      def ac1506
        setting_value("ac1506")&.to_i || 0
      end

      def ac1518a
        setting_value("ac1518a") || "Non"
      end

      # === AML Policy ===

      def ac1201
        setting_value("ac1201") || "Oui"
      end

      def ac1202
        setting_value("ac1202") || "Oui"
      end

      def ac1203
        setting_value("ac1203") || "Oui"
      end

      def ac1204
        setting_value("ac1204") || "Oui"
      end

      def ac1205
        setting_value("ac1205") || "Oui"
      end

      def ac1206
        setting_value("ac1206")
      end

      def ac1207
        setting_value("ac1207") || "Oui"
      end

      def ac1209b
        setting_value("ac1209b") || "Oui"
      end

      def ac1209c
        setting_value("ac1209c") || "Non"
      end

      def ac1208
        setting_value("ac1208") || "Oui"
      end

      def ac1209
        setting_value("ac1209") || "Oui"
      end

      # === Board and Management ===

      def ac1301
        setting_value("ac1301") || "Oui"
      end

      def ac1302
        setting_value("ac1302") || "Oui"
      end

      def ac1303
        setting_value("ac1303") || "Oui"
      end

      def ac1304
        setting_value("ac1304") || "Oui"
      end

      # === Staff ===

      def ac1401
        setting_value("ac1401") || "Non"
      end

      def ac1402
        setting_value("ac1402")&.to_i || 0
      end

      def ac1403
        setting_value("ac1403")
      end

      # === Record Retention ===

      def ac116a
        setting_value("ac116a") || "Oui"
      end

      def ac11601
        setting_value("ac11601")
      end

      # === Audit ===

      def ac11201
        setting_value("ac11201") || "Non"
      end

      def ac1125a
        setting_value("ac1125a") || "Non"
      end

      def ac11301
        setting_value("ac11301") || "Non"
      end

      def ac11302
        setting_value("ac11302")
      end

      def ac11303
        setting_value("ac11303")
      end

      def ac11304
        setting_value("ac11304") || "Non"
      end

      def ac11305
        setting_value("ac11305") || "Non"
      end

      def ac11306
        setting_value("ac11306") || "Non"
      end

      def ac11307
        setting_value("ac11307") || "Non"
      end

      # === Group Information Sharing ===

      def ac12236
        setting_value("ac12236")&.to_i || 0
      end

      def ac12237
        setting_value("ac12237")&.to_i || 0
      end

      def ac12333
        setting_value("ac12333") || "Non"
      end
    end
  end
end
