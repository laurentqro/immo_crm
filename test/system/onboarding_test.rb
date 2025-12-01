# frozen_string_literal: true

require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    # User has an account but no organization yet
    @account = accounts(:one)
    # Remove the existing organization to simulate fresh signup
    organizations(:one).destroy
  end

  test "user without organization is redirected to onboarding from dashboard" do
    login_as @user, scope: :user

    visit dashboard_path

    # Should be redirected to onboarding
    assert_current_path new_onboarding_path
    assert_text "Complete your organization setup"
  end

  test "user can complete onboarding wizard step 1 - entity info" do
    login_as @user, scope: :user

    visit new_onboarding_path

    # Step 1: Entity Information
    assert_text "Entity Information"

    fill_in "Company name", with: "Monaco Premier Immobilier"
    fill_in "RCI number", with: "RCI98765"
    select "Monaco", from: "Country"
    fill_in "Total employees", with: "5"
    fill_in "Compliance officers", with: "1"

    click_button "Continue"

    # Should advance to step 2
    assert_text "Compliance Policies"
  end

  test "user can complete onboarding wizard step 2 - policies" do
    login_as @user, scope: :user

    visit new_onboarding_path

    # Complete step 1 first
    fill_in "Company name", with: "Monaco Premier Immobilier"
    fill_in "RCI number", with: "RCI98765"
    fill_in "Total employees", with: "5"
    fill_in "Compliance officers", with: "1"
    click_button "Continue"

    # Step 2: Compliance Policies
    assert_text "Compliance Policies"

    check "EDD for PEPs"
    check "EDD for high-risk countries"
    check "Written AML/CFT policy"
    select "Annual", from: "Training frequency"

    click_button "Complete Setup"

    # Should redirect to dashboard
    assert_current_path dashboard_path
    assert_text "Organization setup complete"
  end

  test "full onboarding flow creates organization and settings" do
    login_as @user, scope: :user

    visit new_onboarding_path

    # Step 1
    fill_in "Company name", with: "Test Agency Monaco"
    fill_in "RCI number", with: "TESTRCI123"
    fill_in "Total employees", with: "3"
    fill_in "Compliance officers", with: "1"
    click_button "Continue"

    # Step 2
    check "EDD for PEPs"
    check "Written AML/CFT policy"
    select "Annual", from: "Training frequency"
    click_button "Complete Setup"

    # Verify organization was created
    assert_current_path dashboard_path

    # Verify in database
    organization = @account.reload.organization
    assert_not_nil organization
    assert_equal "Test Agency Monaco", organization.name
    assert_equal "TESTRCI123", organization.rci_number
  end

  test "onboarding validates required fields" do
    login_as @user, scope: :user

    visit new_onboarding_path

    # HTML5 required validation prevents form submission client-side
    # Try to continue with empty required fields - should stay on same page
    # (browser validation will block submission)
    click_button "Continue"

    # Should still be on entity_info page since browser validation blocks submission
    # When HTML5 validation fails, we stay on the same page
    assert_current_path new_onboarding_path
    assert_text "Entity Information"
  end

  test "user with existing organization skips onboarding" do
    # Create organization for the user's account
    Organization.create!(
      account: @account,
      name: "Existing Agency",
      rci_number: "EXIST123"
    )

    login_as @user, scope: :user

    visit new_onboarding_path

    # Should redirect to dashboard since org already exists
    assert_current_path dashboard_path
  end
end
