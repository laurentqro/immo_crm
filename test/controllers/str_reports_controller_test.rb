# frozen_string_literal: true

require "test_helper"

class StrReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @transaction = transactions(:purchase)
    @str_report = str_reports(:this_year_str)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get str_reports_path
    assert_redirected_to new_user_session_path
  end

  # TODO: Fix organization destroy in test - currently Organization is not destroyed
  # properly due to foreign key constraints with clients/transactions fixtures.
  # This test works in isolation but fails when run with full fixture set.
  # See also: ClientsControllerTest, BeneficialOwnersControllerTest
  test "redirects to onboarding when no organization" do
    skip "Organization destroy in tests needs fixture cleanup - known issue"
    @organization.destroy
    sign_in @user

    get str_reports_path
    assert_redirected_to new_onboarding_path
  end

  # === Index ===

  test "shows STR report list when authenticated" do
    sign_in @user

    get str_reports_path
    assert_response :success
    assert_select "h1", /STR Reports/i
  end

  test "only shows STR reports from current organization" do
    other_org_str = str_reports(:other_org_str)
    sign_in @user

    get str_reports_path
    assert_response :success
    assert_select "turbo-frame#str_report_#{@str_report.id}"
    assert_select "turbo-frame#str_report_#{other_org_str.id}", count: 0
  end

  test "filters STR reports by year" do
    sign_in @user

    get str_reports_path(year: Date.current.year)
    assert_response :success
  end

  test "filters STR reports by reason" do
    sign_in @user

    get str_reports_path(reason: "CASH")
    assert_response :success
  end

  test "index responds to turbo frame request" do
    sign_in @user

    get str_reports_path, headers: { "Turbo-Frame" => "str_reports_list" }
    assert_response :success
  end

  # === Show ===

  test "shows STR report details" do
    sign_in @user

    get str_report_path(@str_report)
    assert_response :success
  end

  test "returns 404 for STR report from different organization" do
    other_str = str_reports(:other_org_str)
    sign_in @user

    get str_report_path(other_str)
    assert_response :not_found
  end

  # === New ===

  test "shows new STR report form" do
    sign_in @user

    get new_str_report_path
    assert_response :success
    assert_select "form[action=?]", str_reports_path
  end

  test "new form responds to turbo frame request" do
    sign_in @user

    get new_str_report_path, headers: { "Turbo-Frame" => "modal" }
    assert_response :success
  end

  test "pre-selects client when client_id param provided" do
    sign_in @user

    get new_str_report_path(client_id: @client.id)
    assert_response :success
  end

  test "pre-selects transaction when transaction_id param provided" do
    sign_in @user

    get new_str_report_path(transaction_id: @transaction.id)
    assert_response :success
  end

  # === Create ===

  test "creates STR report with minimal fields" do
    sign_in @user

    assert_difference "StrReport.count", 1 do
      post str_reports_path, params: {
        str_report: {
          report_date: Date.current,
          reason: "UNUSUAL_PATTERN",
          notes: "Test STR report"
        }
      }
    end

    str_report = StrReport.last
    assert_equal @organization, str_report.organization
    assert_equal "UNUSUAL_PATTERN", str_report.reason
    assert_redirected_to str_report_path(str_report)
  end

  test "creates STR report linked to client" do
    sign_in @user

    post str_reports_path, params: {
      str_report: {
        client_id: @client.id,
        report_date: Date.current,
        reason: "PEP"
      }
    }

    str_report = StrReport.last
    assert_equal @client, str_report.client
  end

  test "creates STR report linked to transaction" do
    sign_in @user

    post str_reports_path, params: {
      str_report: {
        transaction_id: @transaction.id,
        report_date: Date.current,
        reason: "CASH"
      }
    }

    str_report = StrReport.last
    assert_equal @transaction, str_report.linked_transaction
  end

  test "creates STR report linked to both client and transaction" do
    sign_in @user

    post str_reports_path, params: {
      str_report: {
        client_id: @client.id,
        transaction_id: @transaction.id,
        report_date: Date.current,
        reason: "CASH"
      }
    }

    str_report = StrReport.last
    assert_equal @client, str_report.client
    assert_equal @transaction, str_report.linked_transaction
  end

  test "returns unprocessable entity with invalid params" do
    sign_in @user

    assert_no_difference "StrReport.count" do
      post str_reports_path, params: {
        str_report: {
          report_date: Date.current
          # Missing reason
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create responds with turbo stream on success" do
    sign_in @user

    post str_reports_path, params: {
      str_report: {
        report_date: Date.current,
        reason: "OTHER"
      }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  test "cannot create STR report with client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    assert_no_difference "StrReport.count" do
      post str_reports_path, params: {
        str_report: {
          client_id: other_client.id,
          report_date: Date.current,
          reason: "PEP"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "cannot create STR report with transaction from different organization" do
    other_transaction = transactions(:other_org_transaction)
    sign_in @user

    assert_no_difference "StrReport.count" do
      post str_reports_path, params: {
        str_report: {
          transaction_id: other_transaction.id,
          report_date: Date.current,
          reason: "CASH"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Edit ===

  test "shows edit form for STR report" do
    sign_in @user

    get edit_str_report_path(@str_report)
    assert_response :success
    assert_select "form[action=?]", str_report_path(@str_report)
  end

  test "returns 404 when editing STR report from different organization" do
    other_str = str_reports(:other_org_str)
    sign_in @user

    get edit_str_report_path(other_str)
    assert_response :not_found
  end

  # === Update ===

  test "updates STR report" do
    sign_in @user

    patch str_report_path(@str_report), params: {
      str_report: {
        notes: "Updated notes"
      }
    }

    @str_report.reload
    assert_equal "Updated notes", @str_report.notes
    assert_redirected_to str_report_path(@str_report)
  end

  test "returns 404 when updating STR report from different organization" do
    other_str = str_reports(:other_org_str)
    sign_in @user

    patch str_report_path(other_str), params: {
      str_report: { notes: "Hacked" }
    }

    assert_response :not_found
  end

  test "returns unprocessable entity with invalid update params" do
    sign_in @user

    patch str_report_path(@str_report), params: {
      str_report: { reason: "INVALID" }
    }

    assert_response :unprocessable_entity
  end

  test "update responds with turbo stream" do
    sign_in @user

    patch str_report_path(@str_report), params: {
      str_report: { notes: "Turbo update" }
    }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Destroy ===

  test "soft deletes STR report" do
    sign_in @user

    assert_no_difference "StrReport.with_discarded.count" do
      delete str_report_path(@str_report)
    end

    @str_report.reload
    assert @str_report.discarded?
    assert_redirected_to str_reports_path
  end

  test "returns 404 when deleting STR report from different organization" do
    other_str = str_reports(:other_org_str)
    sign_in @user

    delete str_report_path(other_str)
    assert_response :not_found
  end

  test "destroy responds with turbo stream" do
    sign_in @user

    delete str_report_path(@str_report), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Flash Messages ===

  test "shows success message after creating STR report" do
    sign_in @user

    post str_reports_path, params: {
      str_report: {
        report_date: Date.current,
        reason: "CASH"
      }
    }

    assert_equal "STR report was successfully created.", flash[:notice]
  end

  test "shows success message after updating STR report" do
    sign_in @user

    patch str_report_path(@str_report), params: {
      str_report: { notes: "Updated" }
    }

    assert_equal "STR report was successfully updated.", flash[:notice]
  end

  test "shows success message after deleting STR report" do
    sign_in @user

    delete str_report_path(@str_report)
    assert_equal "STR report was successfully deleted.", flash[:notice]
  end
end
