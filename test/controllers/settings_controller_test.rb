# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @entity_name = settings(:entity_name)
    @edd_for_peps = settings(:edd_for_peps)
  end

  # === Authentication ===

  test "requires authentication for index" do
    get settings_path
    assert_redirected_to new_user_session_path
  end

  test "requires authentication for update" do
    patch settings_path, params: { settings: {} }
    assert_redirected_to new_user_session_path
  end

  # === Index Action ===

  test "index displays all settings grouped by category" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "h1", /Settings/

    # Should show category sections
    assert_select ".settings-category", minimum: 4
  end

  test "index shows entity info settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "input[name='settings[entity_name]']"
    assert_select "input[name='settings[total_employees]']"
  end

  test "index shows kyc procedure settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "input[name='settings[edd_for_peps]']"
  end

  test "index shows compliance policy settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "input[name='settings[written_aml_policy]']"
  end

  test "index shows training settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "select[name='settings[training_frequency]']"
  end

  test "index pre-fills values from existing settings" do
    sign_in @user

    get settings_path

    assert_response :success
    # Entity name should be pre-filled
    assert_select "input[name='settings[entity_name]'][value=?]", @entity_name.value
  end

  # === Update Action ===

  test "update saves settings values" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        entity_name: "Updated Agency Name",
        total_employees: "10"
      }
    }

    assert_redirected_to settings_path
    assert_equal "Settings saved successfully.", flash[:notice]

    @entity_name.reload
    assert_equal "Updated Agency Name", @entity_name.value
  end

  test "update handles boolean settings" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        edd_for_peps: "false"
      }
    }

    assert_redirected_to settings_path

    @edd_for_peps.reload
    assert_equal "false", @edd_for_peps.value
    assert_equal false, @edd_for_peps.typed_value
  end

  test "update handles date settings" do
    sign_in @user
    policy_date = settings(:policy_last_updated)

    patch settings_path, params: {
      settings: {
        policy_last_updated: "2025-12-01"
      }
    }

    assert_redirected_to settings_path

    policy_date.reload
    assert_equal "2025-12-01", policy_date.value
  end

  test "update handles integer settings" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        total_employees: "15"
      }
    }

    assert_redirected_to settings_path

    employees = settings(:total_employees)
    employees.reload
    assert_equal 15, employees.typed_value
  end

  test "update creates settings that do not exist" do
    sign_in @user

    # Delete a setting first
    @entity_name.destroy

    patch settings_path, params: {
      settings: {
        entity_name: "New Agency"
      }
    }

    assert_redirected_to settings_path
    # Setting should be created
    new_setting = @organization.settings.find_by(key: "entity_name")
    assert_not_nil new_setting
    assert_equal "New Agency", new_setting.value
  end

  test "update only affects current organization settings" do
    sign_in @user
    other_org_setting = settings(:other_org_entity_name)
    original_value = other_org_setting.value

    patch settings_path, params: {
      settings: {
        entity_name: "My Updated Name"
      }
    }

    # Other org's setting should be unchanged
    other_org_setting.reload
    assert_equal original_value, other_org_setting.value
  end

  # === Category Filtering ===

  test "can filter by category parameter" do
    sign_in @user

    get settings_path(category: "entity_info")

    assert_response :success
    # Should highlight the entity_info category
    assert_select ".category-tab.active", text: /Entity Info/i
  end

  # === Turbo Stream Responses ===

  test "update responds with turbo stream when requested" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        entity_name: "Turbo Updated"
      }
    }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  # === Validation Errors ===

  test "update handles empty values gracefully" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        entity_name: ""
      }
    }

    # Should still redirect (empty is valid for optional settings)
    assert_redirected_to settings_path
  end

  # === Policy Authorization ===

  test "user without organization access cannot view settings" do
    other_user = users(:two)
    # Ensure other_user is only in organization :two
    sign_in other_user

    get settings_path

    # Should see their own organization's settings, not org one's
    assert_response :success
  end

  # === XHR/Partial Updates ===

  test "partial update via turbo frame" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        edd_for_peps: "true"
      }
    }, headers: { "Turbo-Frame" => "settings_form" }

    # Turbo frames follow redirects automatically
    assert_redirected_to settings_path
  end

  # === Flash Messages ===

  test "successful update shows success message" do
    sign_in @user

    patch settings_path, params: {
      settings: { entity_name: "Flash Test" }
    }

    assert_redirected_to settings_path
    follow_redirect!

    assert_select "#flash", /Settings saved/i
  end

  # === Batch Update ===

  test "can update multiple settings at once" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        entity_name: "Batch Name",
        total_employees: "20",
        edd_for_peps: "true",
        written_aml_policy: "true"
      }
    }

    assert_redirected_to settings_path

    assert_equal "Batch Name", settings(:entity_name).reload.value
    assert_equal "20", settings(:total_employees).reload.value
    assert_equal "true", settings(:edd_for_peps).reload.value
    assert_equal "true", settings(:written_aml_policy).reload.value
  end
end
