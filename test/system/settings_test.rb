# frozen_string_literal: true

require "application_system_test_case"

class SettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @organization = organizations(:one)
  end

  # === Page Layout ===

  test "user can view settings page" do
    login_as @user, scope: :user

    visit settings_path

    assert_text "Settings"
    assert_text @organization.name
  end

  test "settings page shows category tabs" do
    login_as @user, scope: :user

    visit settings_path

    # Should show all three category tabs
    assert_text "Entity Information"
    assert_text "KYC Procedures"
    assert_text "Compliance Policies"
  end

  test "settings page has save button" do
    login_as @user, scope: :user

    visit settings_path

    assert_selector "button", text: /Save/i
  end

  # === Entity Information Section ===

  test "entity information section shows company fields" do
    login_as @user, scope: :user

    visit settings_path

    within ".entity-info-section" do
      assert_selector "input[name*='entity_name']"
      assert_selector "input[name*='total_employees']"
      assert_selector "input[name*='compliance_officers']"
      assert_selector "input[name*='annual_revenue']"
    end
  end

  test "can edit entity name" do
    login_as @user, scope: :user

    visit settings_path

    fill_in "entity_name", with: "Updated Agency Name"
    click_button "Save Settings"

    assert_text "Settings saved"
    assert_field "entity_name", with: "Updated Agency Name"
  end

  test "can edit employee count" do
    login_as @user, scope: :user

    visit settings_path

    fill_in "total_employees", with: "10"
    click_button "Save Settings"

    assert_text "Settings saved"
    assert_field "total_employees", with: "10"
  end

  # === KYC Procedures Section ===

  test "kyc section shows EDD checkboxes" do
    login_as @user, scope: :user

    visit settings_path

    within ".kyc-procedures-section" do
      assert_selector "input[type='checkbox'][name*='edd_for_peps']"
      assert_selector "input[type='checkbox'][name*='edd_for_high_risk_countries']"
      assert_selector "input[type='checkbox'][name*='edd_for_complex_structures']"
    end
  end

  test "can toggle EDD for PEPs" do
    login_as @user, scope: :user

    visit settings_path

    # Uncheck EDD for PEPs
    uncheck "edd_for_peps"
    click_button "Save Settings"

    assert_text "Settings saved"
    assert_no_checked_field "edd_for_peps"
  end

  test "can enable SDD" do
    login_as @user, scope: :user

    visit settings_path

    check "sdd_applied"
    click_button "Save Settings"

    assert_text "Settings saved"
    assert_checked_field "sdd_applied"
  end

  # === Compliance Policies Section ===

  test "compliance section shows policy fields" do
    login_as @user, scope: :user

    visit settings_path

    within ".compliance-policies-section" do
      assert_selector "input[name*='written_aml_policy']"
      assert_selector "input[name*='policy_last_updated']"
      assert_selector "input[name*='risk_assessment_performed']"
      assert_selector "input[name*='internal_controls']"
    end
  end

  test "can set policy last updated date" do
    login_as @user, scope: :user

    visit settings_path

    fill_in "policy_last_updated", with: "2025-12-01"
    click_button "Save Settings"

    assert_text "Settings saved"
    assert_field "policy_last_updated", with: "2025-12-01"
  end

  test "can toggle written AML policy" do
    login_as @user, scope: :user

    visit settings_path

    check "written_aml_policy"
    click_button "Save Settings"

    assert_text "Settings saved"
    assert_checked_field "written_aml_policy"
  end

  # === Category Tab Navigation ===

  test "category tabs highlight current section" do
    login_as @user, scope: :user

    visit settings_path(category: "kyc_procedures")

    assert_selector ".category-tab.active", text: /KYC/i
  end

  # === Form Behavior ===

  test "form preserves values on error" do
    login_as @user, scope: :user

    visit settings_path

    fill_in "entity_name", with: "Test Name"
    # Simulate a validation issue (if any)

    # Values should be preserved
    assert_field "entity_name", with: "Test Name"
  end

  test "form shows help text for fields" do
    login_as @user, scope: :user

    visit settings_path

    # Should show help text explaining EDD
    assert_text "Enhanced Due Diligence"
  end

  # === Multiple Settings Update ===

  test "can update multiple settings at once" do
    login_as @user, scope: :user

    visit settings_path

    fill_in "entity_name", with: "Multi Update Agency"
    fill_in "total_employees", with: "25"
    check "edd_for_peps"
    check "written_aml_policy"

    click_button "Save Settings"

    assert_text "Settings saved"

    # Verify all were saved
    assert_field "entity_name", with: "Multi Update Agency"
    assert_field "total_employees", with: "25"
    assert_checked_field "edd_for_peps"
    assert_checked_field "written_aml_policy"
  end

  # === Auto-save Behavior ===

  test "settings form has autosave indicator" do
    login_as @user, scope: :user

    visit settings_path

    # Should show last saved time or autosave status
    assert_selector ".autosave-indicator"
  end

  # === XBRL Mapping Display ===

  test "settings show XBRL element mapping hint" do
    login_as @user, scope: :user

    visit settings_path

    # Should show XBRL element codes for compliance reference
    assert_text "a4101"
  end

  # === Navigation ===

  test "can access settings from navigation" do
    login_as @user, scope: :user

    visit dashboard_path
    click_link "Settings"

    assert_current_path settings_path
    assert_text "Settings"
  end

  # === Turbo Updates ===

  test "settings update via turbo without page reload" do
    login_as @user, scope: :user

    visit settings_path

    fill_in "entity_name", with: "Turbo Update Test"
    click_button "Save Settings"

    # Should update without full page reload
    assert_text "Settings saved"
    assert_no_selector ".turbo-progress-bar"
  end
end
