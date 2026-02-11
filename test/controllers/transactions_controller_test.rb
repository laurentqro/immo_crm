# frozen_string_literal: true

require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @transaction = transactions(:purchase)
  end

  # === Authentication ===

  test "redirects to login when not authenticated" do
    get transactions_path
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

    get transactions_path
    assert_redirected_to new_onboarding_path
  end

  # === Index ===

  test "shows transaction list when authenticated" do
    sign_in @user

    get transactions_path
    assert_response :success
    assert_select "h1", /Transactions/i
  end

  test "only shows transactions from current organization" do
    other_org_transaction = transactions(:other_org_transaction)
    sign_in @user

    get transactions_path
    assert_response :success
    assert_select "turbo-frame#transaction_#{@transaction.id}"
    assert_select "turbo-frame#transaction_#{other_org_transaction.id}", count: 0
  end

  test "filters transactions by type" do
    sign_in @user

    get transactions_path(transaction_type: "PURCHASE")
    assert_response :success
  end

  test "filters transactions by year" do
    sign_in @user

    get transactions_path(year: Date.current.year)
    assert_response :success
  end

  test "filters transactions by payment method" do
    sign_in @user

    get transactions_path(payment_method: "WIRE")
    assert_response :success
  end

  test "searches transactions by reference" do
    sign_in @user

    get transactions_path(q: @transaction.reference)
    assert_response :success
  end

  test "index responds to turbo frame request" do
    sign_in @user

    get transactions_path, headers: {"Turbo-Frame" => "transactions_list"}
    assert_response :success
  end

  # === Show ===

  test "shows transaction details" do
    sign_in @user

    get transaction_path(@transaction)
    assert_response :success
  end

  test "returns 404 for transaction from different organization" do
    other_transaction = transactions(:other_org_transaction)
    sign_in @user

    get transaction_path(other_transaction)
    assert_response :not_found
  end

  # === New ===

  test "shows new transaction form" do
    sign_in @user

    get new_transaction_path
    assert_response :success
    assert_select "form[action=?]", transactions_path
  end

  test "new form responds to turbo frame request" do
    sign_in @user

    get new_transaction_path, headers: {"Turbo-Frame" => "modal"}
    assert_response :success
  end

  test "pre-selects client when client_id param provided" do
    sign_in @user

    get new_transaction_path(client_id: @client.id)
    assert_response :success
  end

  # === Create ===

  test "creates transaction" do
    sign_in @user

    assert_difference "Transaction.count", 1 do
      post transactions_path, params: {
        transaction: {
          client_id: @client.id,
          transaction_date: Date.current,
          transaction_type: "PURCHASE",
          transaction_value: 1_500_000,
          payment_method: "WIRE",
          agency_role: "BUYER_AGENT"
        }
      }
    end

    transaction = Transaction.last
    assert_equal @client, transaction.client
    assert_equal @organization, transaction.organization
    assert_equal "PURCHASE", transaction.transaction_type
    assert_redirected_to transaction_path(transaction)
  end

  test "creates transaction with cash payment" do
    sign_in @user

    post transactions_path, params: {
      transaction: {
        client_id: @client.id,
        transaction_date: Date.current,
        transaction_type: "SALE",
        transaction_value: 500_000,
        payment_method: "MIXED",
        cash_amount: 50_000
      }
    }

    transaction = Transaction.last
    assert_equal "MIXED", transaction.payment_method
    assert_equal 50_000, transaction.cash_amount
  end

  test "creates purchase with purpose" do
    sign_in @user

    post transactions_path, params: {
      transaction: {
        client_id: @client.id,
        transaction_date: Date.current,
        transaction_type: "PURCHASE",
        purchase_purpose: "INVESTMENT"
      }
    }

    transaction = Transaction.last
    assert_equal "INVESTMENT", transaction.purchase_purpose
  end

  test "returns unprocessable entity with invalid params" do
    sign_in @user

    assert_no_difference "Transaction.count" do
      post transactions_path, params: {
        transaction: {
          client_id: @client.id,
          transaction_type: "PURCHASE"
          # Missing transaction_date
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create redirects on turbo stream success" do
    sign_in @user

    post transactions_path, params: {
      transaction: {
        client_id: @client.id,
        transaction_date: Date.current,
        transaction_type: "RENTAL"
      }
    }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

    assert_response :redirect
  end

  test "cannot create transaction with client from different organization" do
    other_client = clients(:other_org_client)
    sign_in @user

    assert_no_difference "Transaction.count" do
      post transactions_path, params: {
        transaction: {
          client_id: other_client.id,
          transaction_date: Date.current,
          transaction_type: "PURCHASE"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # === Edit ===

  test "shows edit form for transaction" do
    sign_in @user

    get edit_transaction_path(@transaction)
    assert_response :success
    assert_select "form[action=?]", transaction_path(@transaction)
  end

  test "returns 404 when editing transaction from different organization" do
    other_transaction = transactions(:other_org_transaction)
    sign_in @user

    get edit_transaction_path(other_transaction)
    assert_response :not_found
  end

  # === Update ===

  test "updates transaction" do
    sign_in @user

    patch transaction_path(@transaction), params: {
      transaction: {
        transaction_value: 2_000_000
      }
    }

    @transaction.reload
    assert_equal 2_000_000, @transaction.transaction_value
    assert_redirected_to transaction_path(@transaction)
  end

  test "returns 404 when updating transaction from different organization" do
    other_transaction = transactions(:other_org_transaction)
    sign_in @user

    patch transaction_path(other_transaction), params: {
      transaction: {transaction_value: 999_999}
    }

    assert_response :not_found
  end

  test "returns unprocessable entity with invalid update params" do
    sign_in @user

    patch transaction_path(@transaction), params: {
      transaction: {transaction_type: "INVALID"}
    }

    assert_response :unprocessable_entity
  end

  test "update responds with turbo stream" do
    sign_in @user

    patch transaction_path(@transaction), params: {
      transaction: {notes: "Updated notes"}
    }, headers: {"Accept" => "text/vnd.turbo-stream.html"}

    assert_response :redirect
    assert_redirected_to transaction_path(@transaction)
  end

  # === Destroy ===

  test "soft deletes transaction" do
    sign_in @user

    assert_no_difference "Transaction.with_discarded.count" do
      delete transaction_path(@transaction)
    end

    @transaction.reload
    assert @transaction.discarded?
    assert_redirected_to transactions_path
  end

  test "returns 404 when deleting transaction from different organization" do
    other_transaction = transactions(:other_org_transaction)
    sign_in @user

    delete transaction_path(other_transaction)
    assert_response :not_found
  end

  test "destroy responds with turbo stream" do
    sign_in @user

    delete transaction_path(@transaction), headers: {"Accept" => "text/vnd.turbo-stream.html"}
    assert_response :success
    assert_includes response.media_type, "turbo-stream"
  end

  # === Flash Messages ===

  test "shows success message after creating transaction" do
    sign_in @user

    post transactions_path, params: {
      transaction: {
        client_id: @client.id,
        transaction_date: Date.current,
        transaction_type: "PURCHASE"
      }
    }

    assert_equal "Transaction was successfully created.", flash[:notice]
  end

  test "shows success message after updating transaction" do
    sign_in @user

    patch transaction_path(@transaction), params: {
      transaction: {notes: "Updated"}
    }

    assert_equal "Transaction was successfully updated.", flash[:notice]
  end

  test "shows success message after deleting transaction" do
    sign_in @user

    delete transaction_path(@transaction)
    assert_equal "Transaction was successfully deleted.", flash[:notice]
  end
end
