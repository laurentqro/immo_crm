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

      # C7 — aC1201: Has written AML/CFT policies and procedures?
      # Type: enum (Oui/Non) — settings-based
      def ac1201
        setting_value_for("has_written_aml_policies")
      end

      # C8 — aC1202: Policies approved by board/senior management?
      # Type: enum (Oui/Non) — settings-based, conditional on aC114
      def ac1202
        return nil unless ac114 == "Oui"
        setting_value_for("policies_approved_by_board")
      end

      # C9 — aC1203: Policies disseminated to all employees?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1201
      def ac1203
        return nil unless ac1201 == "Oui"
        setting_value_for("policies_disseminated_to_employees")
      end

      # C10 — aC1204: Ensured employees know the policies?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1201
      def ac1204
        return nil unless ac1201 == "Oui"
        setting_value_for("employees_aware_of_policies")
      end

      # C11 — aC1205: Updated AML/CFT policies in past year?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1201
      def ac1205
        return nil unless ac1201 == "Oui"
        setting_value_for("policies_updated_past_year")
      end

      # C12 — aC1206: Date of last policy update
      # Type: xbrli:dateItemType — settings-based, conditional on aC1201
      def ac1206
        return nil unless ac1201 == "Oui"
        setting_value_for("last_policy_update_date")
      end

      # C13 — aC1207: Systematic tracking of policy changes?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1201
      def ac1207
        return nil unless ac1201 == "Oui"
        setting_value_for("systematic_policy_change_tracking")
      end

      # C14 — aC1209B: Has group-wide AML/CFT program?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1518A
      def ac1209b
        return nil unless ac1518a == "Oui"
        setting_value_for("has_group_aml_program")
      end

      # C15 — aC1209C: Analyzed group AML program for local compliance?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1209B
      def ac1209c
        return nil unless ac1209b == "Oui"
        setting_value_for("group_aml_program_compliance_analyzed")
      end

      # C16 — aC1208: Who prepared the policies?
      # Type: enum (4 values) — settings-based, conditional on aC1201
      def ac1208
        return nil unless ac1201 == "Oui"
        setting_value_for("policy_preparer")
      end

      # C17 — aC1209: Has self-assessed AML/CFT procedures adequacy?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1201
      def ac1209
        return nil unless ac1201 == "Oui"
        setting_value_for("self_assessed_aml_adequacy")
      end

      # C18 — aC1301: Board/senior management demonstrates overall AML/CFT responsibility?
      # Type: enum (Oui/Non) — settings-based, conditional on aC114
      def ac1301
        return nil unless ac114 == "Oui"
        setting_value_for("board_demonstrates_aml_responsibility")
      end

      # C19 — aC1302: Board/senior management receives regular AML/CFT reports?
      # Type: enum (Oui/Non) — settings-based, conditional on aC114
      def ac1302
        return nil unless ac114 == "Oui"
        setting_value_for("board_receives_aml_reports")
      end

      # C20 — aC1303: Board/senior management ensures AML/CFT shortcomings are corrected?
      # Type: enum (Oui/Non) — settings-based, conditional on aC114
      def ac1303
        return nil unless ac114 == "Oui"
        setting_value_for("board_corrects_aml_shortcomings")
      end

      # C21 — aC1304: Senior management approves high-risk client acceptance?
      # Type: enum (Oui/Non) — settings-based, conditional on aC114
      def ac1304
        return nil unless ac114 == "Oui"
        setting_value_for("senior_mgmt_approves_high_risk_clients")
      end

      # C22 — aC1401: Entity had AML/CFT violations in past 5 years?
      # Type: enum (Oui/Non) — settings-based
      def ac1401
        setting_value_for("had_aml_violations_past_5_years")
      end

      # C23 — aC1402: Total AML/CFT violations in past 5 years
      # Type: xbrli:integerItemType — settings-based, conditional on aC1401
      def ac1402
        return nil unless ac1401 == "Oui"
        setting_value_for("aml_violations_count_past_5_years")
      end

      # C24 — aC1403: Number and type of AML/CFT violations
      # Type: xbrli:stringItemType — settings-based, conditional on aC1401
      def ac1403
        return nil unless ac1401 == "Oui"
        setting_value_for("aml_violations_description")
      end

      # C25 — aC1501: AML/CFT training provided to directors/management?
      # Type: enum (Oui/Non) — settings-based, conditional on aC114
      def ac1501
        return nil unless ac114 == "Oui"
        setting_value_for("aml_training_provided_to_directors")
      end

      # C26 — aC1503B: AML/CFT training provided to office employees?
      # Type: enum (Oui/Non) — settings-based
      def ac1503b
        setting_value_for("aml_training_provided_to_staff")
      end

      # C27 — aC1506: Total employees trained on AML/CFT
      # Type: xbrli:integerItemType — settings-based
      def ac1506
        setting_value_for("total_employees_trained_aml")
      end

      # ============================================================
      # Section 1.6 — CDD (C28–C66)
      # ============================================================

      # C28 — aC1625: Records ID card info for NP clients?
      # Type: enum (Oui/Non) — settings-based
      def ac1625
        setting_value_for("records_id_card_info")
      end

      # C29 — aC1626: Records passport info?
      # Type: enum (Oui/Non) — settings-based
      def ac1626
        setting_value_for("records_passport_info")
      end

      # C30 — aC1627: Records residence permit info?
      # Type: enum (Oui/Non) — settings-based
      def ac1627
        setting_value_for("records_residence_permit_info")
      end

      # C31 — aC168: Records proof of address?
      # Type: enum (Oui/Non) — settings-based
      def ac168
        setting_value_for("records_proof_of_address")
      end

      # C32 — aC1629: Records other individual info?
      # Type: enum (Oui/Non) — settings-based
      def ac1629
        setting_value_for("records_other_individual_info")
      end

      # C33 — aC1630: Specify other individual info
      # Type: xbrli:stringItemType — settings-based, conditional on aC1629
      def ac1630
        return nil unless ac1629 == "Oui"
        setting_value_for("other_individual_info_details")
      end

      # C34 — aC1601: All required NP elements kept on file?
      # Type: enum (Oui/Non) — settings-based
      def ac1601
        setting_value_for("all_np_elements_on_file")
      end

      # C35 — aC1602: Specify which elements not collected
      # Type: xbrli:stringItemType — settings-based, conditional on aC1601 == "Non"
      def ac1602
        return nil unless ac1601 == "Non"
        setting_value_for("missing_np_elements_description")
      end

      # C36 — aC1631: Records commercial registry extract for LE?
      # Type: enum (Oui/Non) — settings-based
      def ac1631
        setting_value_for("records_commercial_registry_extract")
      end

      # C37 — aC1633: Records articles of association for LE?
      # Type: enum (Oui/Non) — settings-based
      def ac1633
        setting_value_for("records_articles_of_association")
      end

      # C38 — aC1634: Records minutes of general assembly for LE?
      # Type: enum (Oui/Non) — settings-based
      def ac1634
        setting_value_for("records_minutes_of_assembly")
      end

      # C39 — aC1635: Records BO identity documents for LE?
      # Type: enum (Oui/Non) — settings-based
      def ac1635
        setting_value_for("records_bo_identity_documents")
      end

      # C40 — aC1636: Records other LE/construction data?
      # Type: enum (Oui/Non) — settings-based
      def ac1636
        setting_value_for("records_other_le_data")
      end

      # C41 — aC1637: Specify other LE data
      # Type: xbrli:stringItemType — settings-based, conditional on aC1636
      def ac1637
        return nil unless ac1636 == "Oui"
        setting_value_for("other_le_data_details")
      end

      # C42 — aC1608: Former client data accessible to AMSF on request?
      # Type: enum (Oui/Non) — settings-based
      def ac1608
        setting_value_for("former_client_data_accessible_to_amsf")
      end

      # C43 — aC1635A: All documents systematically retained?
      # Type: enum (Oui/Non) — settings-based
      def ac1635a
        setting_value_for("documents_systematically_retained")
      end

      # C44 — aC1638A: Retains summary documents?
      # Type: enum (Oui/Non) — settings-based
      def ac1638a
        setting_value_for("retains_summary_documents")
      end

      # C45 — aC1639A: Info stored in database?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1638A
      def ac1639a
        return nil unless ac1638a == "Oui"
        setting_value_for("info_stored_in_database")
      end

      # C46 — aC1641A: Uses CDD tools?
      # Type: enum (Oui/Non) — settings-based
      def ac1641a
        setting_value_for("uses_cdd_tools")
      end

      # C47 — aC1640A: Which CDD tools?
      # Type: xbrli:stringItemType — settings-based, conditional on aC1641A
      def ac1640a
        return nil unless ac1641a == "Oui"
        setting_value_for("cdd_tools_description")
      end

      # C48 — aC1642A: CDD tool results systematically stored?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1641A
      def ac1642a
        return nil unless ac1641a == "Oui"
        setting_value_for("cdd_results_systematically_stored")
      end

      # C49 — aC1609: Risk-based approach for CDD?
      # Type: enum (Oui/Non) — settings-based
      def ac1609
        setting_value_for("risk_based_approach_for_cdd")
      end

      # C50 — aC1610: Policies distinguish CDD levels?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1609
      def ac1610
        return nil unless ac1609 == "Oui"
        setting_value_for("policies_distinguish_cdd_levels")
      end

      # C51 — aC1611: Total unique active clients
      # Type: xbrli:integerItemType — settings-based, conditional on aC1609
      def ac1611
        return nil unless ac1609 == "Oui"
        setting_value_for("total_unique_active_clients_cdd")
      end

      # C52 — aC1612A: Implemented simplified due diligence?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1609
      def ac1612a
        return nil unless ac1609 == "Oui"
        setting_value_for("implemented_simplified_dd")
      end

      # C53 — aC1612: Total clients with simplified DD
      # Type: xbrli:integerItemType — settings-based, conditional on aC1612A
      def ac1612
        return nil unless ac1612a == "Oui"
        setting_value_for("simplified_dd_client_count")
      end

      # C54 — aC1614: Identifies/verifies clients using reliable independent info?
      # Type: enum (Oui/Non) — settings-based
      def ac1614
        setting_value_for("verifies_clients_with_reliable_info")
      end

      # C55 — aC1615: CDD policies include client acceptance/identification procedures?
      # Type: enum (Oui/Non) — settings-based
      def ac1615
        setting_value_for("cdd_policies_include_acceptance_procedures")
      end

      # C56 — aC1622F: Uses third parties for CDD?
      # Type: enum (Oui/Non) — settings-based
      def ac1622f
        setting_value_for("uses_third_parties_for_cdd")
      end

      # C57 — aC1622A: Difficulties receiving CDD info from third parties?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1622F
      def ac1622a
        return nil unless ac1622f == "Oui"
        setting_value_for("difficulties_receiving_cdd_from_third_parties")
      end

      # C58 — aC1622B: Main reason for difficulties
      # Type: xbrli:stringItemType — settings-based, conditional on aC1622A
      def ac1622b
        return nil unless ac1622a == "Oui"
        setting_value_for("cdd_difficulties_reason")
      end

      # C59 — aC1620: Enhanced identification for high-risk clients?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1609
      def ac1620
        return nil unless ac1609 == "Oui"
        setting_value_for("enhanced_id_for_high_risk_clients")
      end

      # C60 — aC1617: Examines source of wealth before relationship?
      # Type: enum (Oui/Non) — settings-based
      def ac1617
        setting_value_for("examines_source_of_wealth")
      end

      # C61 — aC1616B: Frequency of high-risk purchase/sale client review
      # Type: enum (5 values) — settings-based, conditional on aC1609
      def ac1616b
        return nil unless ac1609 == "Oui"
        setting_value_for("high_risk_purchase_sale_review_frequency")
      end

      # C62 — aC1616A: Frequency of high-risk rental client review
      # Type: enum (5 values) — settings-based, conditional on aC1609
      def ac1616a
        return nil unless ac1609 == "Oui"
        setting_value_for("high_risk_rental_review_frequency")
      end

      # C63 — aC1618: Other measures for high-risk clients?
      # Type: enum (Oui/Non) — settings-based, conditional on aC1609
      def ac1618
        return nil unless ac1609 == "Oui"
        setting_value_for("other_measures_for_high_risk_clients")
      end

      # C64 — aC1619: Specify other high-risk measures
      # Type: xbrli:stringItemType — settings-based, conditional on aC1618
      def ac1619
        return nil unless ac1618 == "Oui"
        setting_value_for("other_high_risk_measures_description")
      end

      # C65 — aC1616C: Clients use cryptocurrency for real estate?
      # Type: enum (Oui/Non) — settings-based
      def ac1616c
        setting_value_for("clients_use_crypto_for_real_estate")
      end

      # C66 — aC1621: How entity verifies virtual asset BOs
      # Type: xbrli:stringItemType — settings-based, conditional on aC1616C
      def ac1621
        return nil unless ac1616c == "Oui"
        setting_value_for("virtual_asset_bo_verification_method")
      end

      # ============================================================
      # Section 1.7 — EDD (C67–C69)
      # ============================================================

      # C67 — aC1701: Total EDD clients at onboarding
      # Type: xbrli:integerItemType — settings-based, conditional on aC1609
      def ac1701
        return nil unless ac1609 == "Oui"
        setting_value_for("edd_clients_at_onboarding_count")
      end

      # C68 — aC1702: Total EDD clients during ongoing relationship
      # Type: xbrli:integerItemType — settings-based, conditional on aC1609
      def ac1702
        return nil unless ac1609 == "Oui"
        setting_value_for("edd_clients_ongoing_count")
      end

      # C69 — aC1703: Percentage of EDD clients
      # Type: xbrli:pureItemType (0–100) — settings-based, conditional on aC1609
      def ac1703
        return nil unless ac1609 == "Oui"
        setting_value_for("edd_clients_percentage")
      end

      # ============================================================
      # Section 1.8 — Risk Assessments (C70–C78)
      # ============================================================

      # C70 — aB1801B: Applies risk ratings to clients?
      # Type: enum (Oui/Non) — settings-based
      def ab1801b
        setting_value_for("applies_risk_ratings_to_clients")
      end

      # C71 — aC1801: How many risk levels?
      # Type: xbrli:integerItemType — settings-based, conditional on aB1801B
      def ac1801
        return nil unless ab1801b == "Oui"
        setting_value_for("number_of_risk_levels")
      end

      # C72 — aC1802: Total high-risk clients
      # Type: xbrli:integerItemType — settings-based, conditional on aB1801B
      def ac1802
        return nil unless ab1801b == "Oui"
        setting_value_for("high_risk_clients_count")
      end

      # C73 — aC1806: High-risk considerations include all required factors?
      # Type: enum (Oui/Non) — settings-based, conditional on aB1801B
      def ac1806
        return nil unless ab1801b == "Oui"
        setting_value_for("risk_assessment_includes_all_factors")
      end

      # C74 — aC1807: Specify which elements not considered
      # Type: xbrli:stringItemType — settings-based, conditional on aC1806 == "Non"
      def ac1807
        return nil unless ac1806 == "Non"
        setting_value_for("risk_factors_not_considered")
      end

      # C75 — aC1811: Uses sensitive countries list?
      # Type: enum (Oui/Non) — settings-based, conditional on aB1801B
      def ac1811
        return nil unless ab1801b == "Oui"
        setting_value_for("uses_sensitive_countries_list")
      end

      # C76 — aC1812: Uses sensitive activities list?
      # Type: enum (Oui/Non) — settings-based, conditional on aB1801B
      def ac1812
        return nil unless ab1801b == "Oui"
        setting_value_for("uses_sensitive_activities_list")
      end

      # C77 — aC1813: Which high-risk client activities?
      # Type: xbrli:stringItemType — settings-based, conditional on aC1812
      def ac1813
        return nil unless ac1812 == "Oui"
        setting_value_for("high_risk_client_activities")
      end

      # C78 — aC1814W: Examines ML and TF risks separately?
      # Type: enum (Oui/Non) — settings-based, conditional on aB1801B
      def ac1814w
        return nil unless ab1801b == "Oui"
        setting_value_for("separates_ml_and_tf_risks")
      end

      # ============================================================
      # Section 1.9 — Audit (C79)
      # ============================================================

      # C79 — aC1904: Last AMSF/SICCFIN audit date
      # Type: enum (7 values) — settings-based
      def ac1904
        setting_value_for("last_amsf_audit_recency")
      end

      # ============================================================
      # Section 1.10 — Record Keeping (C80–C84)
      # ============================================================

      # C80 — aC11101: Retains transaction info for 5+ years?
      # Type: enum (Oui/Non) — settings-based
      def ac11101
        setting_value_for("retains_transaction_info_5_years")
      end

      # C81 — aC11102: Retains CDD correspondence for 5+ years?
      # Type: enum (Oui/Non) — settings-based
      def ac11102
        setting_value_for("retains_cdd_correspondence_5_years")
      end

      # C82 — aC11103: Info stored securely?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11101
      def ac11103
        return nil unless ac11101 == "Oui"
        setting_value_for("info_stored_securely")
      end

      # C83 — aC11104: Info available to authorities on request?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11101
      def ac11104
        return nil unless ac11101 == "Oui"
        setting_value_for("info_available_to_authorities")
      end

      # C84 — aC11105: Has data backup and recovery plan?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11101
      def ac11105
        return nil unless ac11101 == "Oui"
        setting_value_for("has_data_backup_recovery_plan")
      end

      # ============================================================
      # Section 1.11 — TFS (C85–C89)
      # ============================================================

      # C85 — aC11201: Policies cover TFS screening?
      # Type: enum (Oui/Non) — settings-based
      def ac11201
        setting_value_for("policies_cover_tfs_screening")
      end

      # C86 — aC1125A: Consults national asset freeze list?
      # Type: enum (Oui/Non) — settings-based
      def ac1125a
        setting_value_for("consults_national_asset_freeze_list")
      end

      # C87 — aC12333: Identified TF/WMD proliferation financing?
      # Type: enum (Oui/Non) — settings-based
      def ac12333
        setting_value_for("identified_tf_or_wmd_financing")
      end

      # C88 — aC12236: Total TF declarations to DBT
      # Type: xbrli:integerItemType — settings-based, conditional on aC12333
      def ac12236
        return nil unless ac12333 == "Oui"
        setting_value_for("tf_declarations_to_dbt_count")
      end

      # C89 — aC12237: Total WMD proliferation declarations to DBT
      # Type: xbrli:integerItemType — settings-based, conditional on aC12333
      def ac12237
        return nil unless ac12333 == "Oui"
        setting_value_for("wmd_proliferation_declarations_to_dbt_count")
      end

      # ============================================================
      # Section 1.12 — PEPs (C90–C96)
      # ============================================================

      # C90 — aC11301: Takes measures to determine PEP status?
      # Type: enum (Oui/Non) — settings-based
      def ac11301
        setting_value_for("takes_measures_to_determine_pep_status")
      end

      # C91 — aC11302: Which measures for PEP determination?
      # Type: xbrli:stringItemType — settings-based, conditional on aC11301
      def ac11302
        return nil unless ac11301 == "Oui"
        setting_value_for("pep_determination_measures")
      end

      # C92 — aC11303: Additional PEP procedures?
      # Type: xbrli:stringItemType — settings-based, conditional on aC11301
      def ac11303
        return nil unless ac11301 == "Oui"
        setting_value_for("additional_pep_procedures")
      end

      # C93 — aC11304: PEP screening for new clients?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11301
      def ac11304
        return nil unless ac11301 == "Oui"
        setting_value_for("pep_screening_for_new_clients")
      end

      # C94 — aC11305: Continuous PEP screening?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11301
      def ac11305
        return nil unless ac11301 == "Oui"
        setting_value_for("continuous_pep_screening")
      end

      # C95 — aC11306: Enhanced PEP surveillance?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11301
      def ac11306
        return nil unless ac11301 == "Oui"
        setting_value_for("enhanced_pep_surveillance")
      end

      # C96 — aC11307: All PEP relationships high-risk?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11301
      def ac11307
        return nil unless ac11301 == "Oui"
        setting_value_for("all_pep_relationships_high_risk")
      end

      # ============================================================
      # Section 1.13 — Cash Transactions (C97–C99)
      # ============================================================

      # C97 — aC11401: Entity performs cash operations?
      # Type: enum (Oui/Non) — settings-based
      def ac11401
        setting_value_for("performs_cash_operations_with_clients")
      end

      # C98 — aC11402: Applies specific AML controls for cash?
      # Type: enum (Oui/Non) — settings-based, conditional on aC11401
      def ac11402
        return nil unless ac11401 == "Oui"
        setting_value_for("applies_aml_controls_for_cash")
      end

      # C99 — aC11403: Describe cash-specific AML controls
      # Type: xbrli:stringItemType — settings-based, conditional on aC11402
      def ac11403
        return nil unless ac11402 == "Oui"
        setting_value_for("cash_aml_controls_description")
      end

      # ============================================================
      # Section 1.14 — STR (C100–C103)
      # ============================================================

      # C100 — aC11501B: Filed STRs/SARs with FIU?
      # Type: enum (Oui/Non) — settings-based
      def ac11501b
        setting_value_for("filed_strs_with_fiu")
      end

      # C101 — aC11502: Total TF-related STRs
      # Type: xbrli:integerItemType — settings-based, conditional on aC11501B
      def ac11502
        return nil unless ac11501b == "Oui"
        setting_value_for("tf_related_strs_count")
      end

      # C102 — aC11504: Total ML-related STRs
      # Type: xbrli:integerItemType — settings-based, conditional on aC11501B
      def ac11504
        return nil unless ac11501b == "Oui"
        setting_value_for("ml_related_strs_count")
      end

      # C103 — aC11508: Taken measures to strengthen internal AML controls?
      # Type: enum (Oui/Non) — settings-based
      def ac11508
        setting_value_for("strengthened_internal_aml_controls")
      end

      # ============================================================
      # Section 1.15 — Comments & Feedback (C104–C105)
      # ============================================================

      # C104 — aC116A: Has comments on controls section?
      # Type: enum (Oui/Non) — settings-based
      def ac116a
        setting_value_for("has_controls_section_comments")
      end

      # C105 — aC11601: Controls section comments
      # Type: xbrli:stringItemType — settings-based, conditional on aC116A
      def ac11601
        return nil unless ac116a == "Oui"
        setting_value_for("controls_section_comments")
      end
    end
  end
end
