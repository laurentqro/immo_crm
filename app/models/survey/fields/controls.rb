# frozen_string_literal: true

class Survey
  module Fields
    module Controls
      # C1 — aC1102A: Total employees at end of reporting period (reuses Q188/a3301)
      # Type: xbrli:integerItemType — settings-based
      def ac1102a
        setting_value_for("total_employee_headcount")
      end

      # C2 — aC1102: FTE employees at end of reporting period
      # Type: xbrli:decimalItemType — settings-based
      def ac1102
        setting_value_for("fte_employees")
      end

      # C3 — aC1101Z: Hours on AML/CFT compliance per month
      # Type: xbrli:decimalItemType — settings-based
      def ac1101z
        setting_value_for("aml_compliance_hours_per_month")
      end

      # C4 — aC114: Has board/senior management?
      # Type: enum (Oui/Non) — settings-based
      def ac114
        setting_value_for("has_board_or_senior_management")
      end

      # C5 — aC1106: Has compliance department?
      # Type: enum (Oui/Non) — settings-based
      def ac1106
        setting_value_for("has_compliance_department")
      end

      # C6 — aC1518A: Entity is part of a group?
      # Type: enum (Oui/Non) — settings-based
      def ac1518a
        setting_value_for("entity_is_part_of_group")
      end
    end
  end
end
