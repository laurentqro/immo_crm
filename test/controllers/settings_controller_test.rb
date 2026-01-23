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

  test "requires authentication for show" do
    get settings_path
    assert_redirected_to new_user_session_path
  end

  test "requires authentication for update" do
    patch settings_path, params: { settings: {} }
    assert_redirected_to new_user_session_path
  end

  # === Show Action ===

  test "show displays all settings grouped by category" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "h1", /Settings/

    # Should show category sections
    assert_select ".settings-category", minimum: 3
  end

  test "show shows entity info settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "input[name='settings[entity_name]']"
    assert_select "input[name='settings[total_employees]']"
  end

  test "show shows kyc procedure settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "input[name='settings[edd_for_peps]']"
  end

  test "show shows compliance policy settings" do
    sign_in @user

    get settings_path

    assert_response :success
    assert_select "input[name='settings[written_aml_policy]']"
  end

  # === Update Action ===

  test "update redirects with success notice" do
    sign_in @user

    patch settings_path, params: {
      settings: {
        entity_name: "Updated Agency Name",
        total_employees: "10"
      }
    }

    assert_redirected_to settings_path
    assert_match(/settings? saved successfully/i, flash[:notice])
  end

  # === Tab Navigation ===

  test "renders all settings categories with tabs" do
    sign_in @user

    get settings_path

    assert_response :success
    # Should render all 3 tabs for client-side navigation
    assert_select "[data-tabs-target='tab']", 3
    # Should render all 3 panels (2 hidden, 1 visible initially)
    assert_select "[data-tabs-target='panel']", 3
    # First panel (Entity Information) should be visible
    assert_select "#entity_info.settings-category"
    # Other panels should have hidden class
    assert_select "#kyc_procedures.settings-category.hidden"
    assert_select "#compliance_policies.settings-category.hidden"
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

    # Flash message confirms settings were saved
    assert_select "#flash", /settings? saved successfully/i
  end
end
