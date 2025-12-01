# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
  end

  # Authentication tests
  test "redirects to login when not authenticated" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "shows dashboard when authenticated with organization" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select "h1", /Dashboard/i
  end

  # Organization requirement tests
  test "redirects to onboarding when user has no organization" do
    # Remove organization
    @organization.destroy

    sign_in @user

    get dashboard_path
    assert_redirected_to new_onboarding_path
    assert_equal "Please complete your organization setup.", flash[:alert]
  end

  # Stats display tests
  test "displays client count" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select ".stats-panel", /Clients/i
  end

  test "displays transaction count" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select ".stats-panel", /Transactions/i
  end

  test "displays submission status" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select ".submission-status"
  end

  # Empty state tests
  test "shows empty state message when no clients" do
    sign_in @user

    get dashboard_path
    assert_response :success
    # Should show prompt to add first client
    assert_select ".empty-state", /Add your first client/i
  end

  test "shows empty state message when no transactions" do
    sign_in @user

    get dashboard_path
    assert_response :success
    # Should show prompt to add first transaction
    assert_select ".empty-state", /No transactions yet/i
  end

  # Quick action buttons tests
  test "displays quick action buttons" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select "a", /Add Client/i
    assert_select "a", /Add Transaction/i
  end

  # Recent transactions tests
  test "displays recent transactions section" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select ".recent-transactions"
  end

  # Submission CTA tests
  test "shows start submission button when no active submission" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select ".submission-cta", /Start.*Submission/i
  end

  # Year filtering
  test "displays stats for current year by default" do
    sign_in @user

    get dashboard_path
    assert_response :success
    assert_select ".year-indicator", /#{Date.current.year}/
  end
end
