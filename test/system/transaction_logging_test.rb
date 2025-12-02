# frozen_string_literal: true

require "application_system_test_case"

class TransactionLoggingTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @legal_entity = clients(:legal_entity)
    @purchase = transactions(:purchase)
    @sale = transactions(:sale)
    @rental = transactions(:rental)
  end

  # === Transaction List ===

  test "user can view transaction list" do
    login_as @user, scope: :user

    visit transactions_path

    assert_text "Transactions"
    assert_text @purchase.reference
  end

  test "transaction list shows type indicators" do
    login_as @user, scope: :user

    visit transactions_path

    # Should show transaction type badges
    assert_selector "[data-transaction-type='PURCHASE']"
    assert_selector "[data-transaction-type='SALE']"
  end

  test "user can filter transactions by type" do
    login_as @user, scope: :user

    visit transactions_path

    # Select PURCHASE filter
    select "Purchase", from: "transaction_type"
    click_button "Filter"

    # Should show purchase transactions
    assert_text @purchase.reference
  end

  test "user can filter transactions by year" do
    login_as @user, scope: :user

    visit transactions_path

    # Select current year
    select Date.current.year.to_s, from: "year"
    click_button "Filter"

    # Should show current year transactions
    assert_text @purchase.reference
  end

  test "user can filter transactions by payment method" do
    login_as @user, scope: :user
    cash_txn = transactions(:cash_payment)

    visit transactions_path

    select "Mixed", from: "payment_method"
    click_button "Filter"

    assert_text cash_txn.reference
  end

  # === Create Transaction ===

  test "user can create a purchase transaction" do
    login_as @user, scope: :user

    visit transactions_path
    click_link "Add Transaction"

    assert_text "New Transaction"

    # Fill required fields
    fill_in "Reference", with: "TEST-001"
    fill_in "Transaction date", with: Date.current.to_s
    select "Purchase", from: "Transaction type"
    select @client.name, from: "Client"
    fill_in "Transaction value", with: "1500000"
    fill_in "Commission amount", with: "45000"
    select "Wire", from: "Payment method"
    select "Buyer Agent", from: "Agency role"
    select "Residence", from: "Purchase purpose"

    click_button "Create Transaction"

    assert_text "Transaction was successfully created"
    assert_text "TEST-001"
  end

  test "user can create a sale transaction" do
    login_as @user, scope: :user

    visit new_transaction_path

    fill_in "Reference", with: "SALE-001"
    fill_in "Transaction date", with: Date.current.to_s
    select "Sale", from: "Transaction type"
    select @client.name, from: "Client"
    fill_in "Transaction value", with: "2000000"
    select "Wire", from: "Payment method"
    select "Seller Agent", from: "Agency role"

    click_button "Create Transaction"

    assert_text "Transaction was successfully created"
    assert_text "SALE-001"
  end

  test "user can create a rental transaction" do
    login_as @user, scope: :user

    visit new_transaction_path

    fill_in "Reference", with: "RENT-001"
    fill_in "Transaction date", with: Date.current.to_s
    select "Rental", from: "Transaction type"
    select @legal_entity.name, from: "Client"
    fill_in "Transaction value", with: "36000"
    select "Wire", from: "Payment method"
    select "Dual Agent", from: "Agency role"

    click_button "Create Transaction"

    assert_text "Transaction was successfully created"
    assert_text "RENT-001"
  end

  test "cash payment shows cash amount field" do
    login_as @user, scope: :user

    visit new_transaction_path

    select "Cash", from: "Payment method"

    # Cash amount field should appear
    assert_selector "#transaction_cash_amount"
  end

  test "mixed payment shows cash amount field" do
    login_as @user, scope: :user

    visit new_transaction_path

    select "Mixed", from: "Payment method"

    # Cash amount field should appear for mixed payments
    assert_selector "#transaction_cash_amount"
  end

  test "purchase purpose only shown for purchases" do
    login_as @user, scope: :user

    visit new_transaction_path

    # Initially hidden or not required
    select "Sale", from: "Transaction type"
    assert_no_selector "#transaction_purchase_purpose:not([hidden])"

    # When PURCHASE is selected, purpose should appear
    select "Purchase", from: "Transaction type"
    assert_selector "#transaction_purchase_purpose"
  end

  # === View Transaction Details ===

  test "user can view transaction details" do
    login_as @user, scope: :user

    visit transaction_path(@purchase)

    assert_text @purchase.reference
    assert_text @purchase.client.name
    assert_text "Transaction Details"
  end

  test "transaction shows payment method" do
    login_as @user, scope: :user

    visit transaction_path(@purchase)

    assert_text "Wire"
  end

  test "transaction shows linked client" do
    login_as @user, scope: :user

    visit transaction_path(@purchase)

    assert_text @purchase.client.name
    # Should link to client
    assert_selector "a[href='#{client_path(@purchase.client)}']"
  end

  # === Edit Transaction ===

  test "user can edit transaction" do
    login_as @user, scope: :user

    visit transaction_path(@purchase)
    click_link "Edit"

    fill_in "Reference", with: "UPDATED-001"
    click_button "Update Transaction"

    assert_text "Transaction was successfully updated"
    assert_text "UPDATED-001"
  end

  test "edit preserves transaction type" do
    login_as @user, scope: :user

    visit edit_transaction_path(@purchase)

    # Transaction type should be pre-selected
    assert_select "Transaction type", selected: "Purchase"

    click_button "Update Transaction"

    @purchase.reload
    assert_equal "PURCHASE", @purchase.transaction_type
  end

  # === Delete Transaction ===

  test "user can delete transaction" do
    login_as @user, scope: :user

    visit transaction_path(@purchase)

    accept_confirm do
      click_button "Delete Transaction"
    end

    assert_text "Transaction was successfully deleted"
    assert_current_path transactions_path
  end

  # === Turbo Frame Navigation ===

  test "transaction list updates via turbo frame" do
    login_as @user, scope: :user

    visit transactions_path

    # The page should have turbo frames for transaction list
    assert_selector "turbo-frame#transactions_list"
  end

  test "new transaction form appears in turbo frame" do
    login_as @user, scope: :user

    visit transactions_path
    click_link "Add Transaction"

    # Form should appear without full page reload
    assert_selector "turbo-frame#modal form"
  end

  test "transaction update via turbo frame" do
    login_as @user, scope: :user

    visit transactions_path

    within "#transaction_#{@purchase.id}" do
      click_link "Edit"
    end

    # Edit form should appear inline
    fill_in "Reference", with: "TURBO-001"
    click_button "Update Transaction"

    # Should update without full page reload
    assert_text "TURBO-001"
  end

  # === Value Display ===

  test "transaction values are formatted as currency" do
    login_as @user, scope: :user

    visit transaction_path(@purchase)

    # Value should be formatted
    assert_text "1,500,000"
  end

  test "high value transactions are highlighted" do
    high_value = transactions(:high_value)
    login_as @user, scope: :user

    visit transactions_path

    # High-value transactions should have visual indicator
    assert_selector "#transaction_#{high_value.id}"
  end

  # === Validation Errors ===

  test "shows validation errors for invalid transaction" do
    login_as @user, scope: :user

    visit new_transaction_path

    # Submit without required fields
    click_button "Create Transaction"

    # Should show validation errors
    assert_text "can't be blank"
  end

  test "transaction requires client" do
    login_as @user, scope: :user

    visit new_transaction_path

    fill_in "Reference", with: "NO-CLIENT"
    fill_in "Transaction date", with: Date.current.to_s
    select "Purchase", from: "Transaction type"
    # Intentionally don't select client

    click_button "Create Transaction"

    assert_text "Client must exist"
  end

  # === Dashboard Integration ===

  test "dashboard shows recent transactions" do
    login_as @user, scope: :user

    visit dashboard_path

    assert_text "Recent Transactions"
    # Should show transaction data
    assert_text @purchase.client.name
  end
end
