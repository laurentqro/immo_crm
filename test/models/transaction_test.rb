# frozen_string_literal: true

require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid transaction with required attributes" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_date: Date.current,
      transaction_type: "PURCHASE"
    )
    assert transaction.valid?
  end

  test "requires organization" do
    transaction = Transaction.new(
      client: @client,
      transaction_date: Date.current,
      transaction_type: "PURCHASE"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:organization], "must exist"
  end

  test "requires client" do
    transaction = Transaction.new(
      organization: @organization,
      transaction_date: Date.current,
      transaction_type: "PURCHASE"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:client], "must exist"
  end

  test "requires transaction_date" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_type: "PURCHASE"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:transaction_date], "can't be blank"
  end

  test "requires transaction_type" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_date: Date.current
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:transaction_type], "can't be blank"
  end

  test "transaction_type must be valid" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_date: Date.current,
      transaction_type: "INVALID"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:transaction_type], "is not included in the list"
  end

  test "accepts all valid transaction_types" do
    %w[PURCHASE SALE RENTAL].each do |type|
      transaction = Transaction.new(
        organization: @organization,
        client: @client,
        transaction_date: Date.current,
        transaction_type: type
      )
      assert transaction.valid?, "Expected transaction_type '#{type}' to be valid"
    end
  end

  # === Optional Field Validations ===

  test "payment_method must be valid when present" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_date: Date.current,
      transaction_type: "PURCHASE",
      payment_method: "INVALID"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:payment_method], "is not included in the list"
  end

  test "accepts all valid payment_methods" do
    %w[WIRE CASH CHECK CRYPTO MIXED].each do |method|
      transaction = Transaction.new(
        organization: @organization,
        client: @client,
        transaction_date: Date.current,
        transaction_type: "PURCHASE",
        payment_method: method
      )
      assert transaction.valid?, "Expected payment_method '#{method}' to be valid"
    end
  end

  test "agency_role must be valid when present" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_date: Date.current,
      transaction_type: "PURCHASE",
      agency_role: "INVALID"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:agency_role], "is not included in the list"
  end

  test "accepts all valid agency_roles" do
    %w[BUYER_AGENT SELLER_AGENT DUAL_AGENT].each do |role|
      transaction = Transaction.new(
        organization: @organization,
        client: @client,
        transaction_date: Date.current,
        transaction_type: "PURCHASE",
        agency_role: role
      )
      assert transaction.valid?, "Expected agency_role '#{role}' to be valid"
    end
  end

  test "purchase_purpose must be valid when present" do
    transaction = Transaction.new(
      organization: @organization,
      client: @client,
      transaction_date: Date.current,
      transaction_type: "PURCHASE",
      purchase_purpose: "INVALID"
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:purchase_purpose], "is not included in the list"
  end

  test "accepts all valid purchase_purposes" do
    %w[RESIDENCE INVESTMENT].each do |purpose|
      transaction = Transaction.new(
        organization: @organization,
        client: @client,
        transaction_date: Date.current,
        transaction_type: "PURCHASE",
        purchase_purpose: purpose
      )
      assert transaction.valid?, "Expected purchase_purpose '#{purpose}' to be valid"
    end
  end

  # === Scopes ===

  test "purchases scope returns only PURCHASE transactions" do
    purchase = transactions(:purchase)
    sale = transactions(:sale)

    purchases = Transaction.purchases
    assert_includes purchases, purchase
    assert_not_includes purchases, sale
  end

  test "sales scope returns only SALE transactions" do
    purchase = transactions(:purchase)
    sale = transactions(:sale)

    sales = Transaction.sales
    assert_includes sales, sale
    assert_not_includes sales, purchase
  end

  test "rentals scope returns only RENTAL transactions" do
    purchase = transactions(:purchase)
    rental = transactions(:rental)

    rentals = Transaction.rentals
    assert_includes rentals, rental
    assert_not_includes rentals, purchase
  end

  test "for_year scope filters by year" do
    this_year = transactions(:purchase)
    last_year = transactions(:last_year_transaction)

    current_year_transactions = Transaction.for_year(Date.current.year)
    assert_includes current_year_transactions, this_year
    assert_not_includes current_year_transactions, last_year
  end

  test "with_cash scope returns transactions with cash payments" do
    cash_transaction = transactions(:cash_payment)
    wire_transaction = transactions(:purchase)

    cash_transactions = Transaction.with_cash
    assert_includes cash_transactions, cash_transaction
    assert_not_includes cash_transactions, wire_transaction
  end

  test "by_payment_method scope filters by payment method" do
    wire_transaction = transactions(:purchase)
    cash_transaction = transactions(:cash_payment)

    wire_transactions = Transaction.by_payment_method("WIRE")
    assert_includes wire_transactions, wire_transaction
    assert_not_includes wire_transactions, cash_transaction
  end

  test "recent scope orders by transaction_date descending" do
    transactions = Transaction.recent
    assert transactions.first.transaction_date >= transactions.last.transaction_date
  end

  # === Soft Delete (Discard) ===

  test "soft deletes transaction with discard" do
    transaction = transactions(:purchase)
    assert_nil transaction.deleted_at

    transaction.discard
    assert_not_nil transaction.deleted_at
    assert transaction.discarded?
  end

  test "kept scope excludes discarded transactions" do
    transaction = transactions(:purchase)
    transaction.discard

    assert_not_includes Transaction.kept, transaction
  end

  test "undiscard restores soft-deleted transaction" do
    transaction = transactions(:purchase)
    transaction.discard
    assert transaction.discarded?

    transaction.undiscard
    assert_not transaction.discarded?
    assert_nil transaction.deleted_at
  end

  # === Associations ===

  test "belongs to organization" do
    transaction = transactions(:purchase)
    assert_equal @organization, transaction.organization
  end

  test "belongs to client" do
    transaction = transactions(:purchase)
    assert_equal @client, transaction.client
  end

  test "has many str_reports" do
    transaction = transactions(:purchase)
    assert_respond_to transaction, :str_reports
  end

  # === Organization Scoping ===

  test "for_organization scope filters by organization" do
    org_one_transaction = transactions(:purchase)
    org_two_transaction = transactions(:other_org_transaction)

    org_one_transactions = Transaction.for_organization(@organization)
    assert_includes org_one_transactions, org_one_transaction
    assert_not_includes org_one_transactions, org_two_transaction
  end

  # === Instance Methods ===

  test "purchase? returns true for PURCHASE type" do
    transaction = transactions(:purchase)
    assert transaction.purchase?
    assert_not transaction.sale?
    assert_not transaction.rental?
  end

  test "sale? returns true for SALE type" do
    transaction = transactions(:sale)
    assert transaction.sale?
    assert_not transaction.purchase?
    assert_not transaction.rental?
  end

  test "rental? returns true for RENTAL type" do
    transaction = transactions(:rental)
    assert transaction.rental?
    assert_not transaction.purchase?
    assert_not transaction.sale?
  end

  test "has_cash? returns true when cash_amount present" do
    transaction = transactions(:cash_payment)
    assert transaction.has_cash?
  end

  test "has_cash? returns false when cash_amount nil or zero" do
    transaction = transactions(:purchase)
    assert_not transaction.has_cash?
  end

  test "transaction_type_label returns human-readable label" do
    assert_equal "Purchase", transactions(:purchase).transaction_type_label
    assert_equal "Sale", transactions(:sale).transaction_type_label
    assert_equal "Rental", transactions(:rental).transaction_type_label
  end

  # === Auditable ===

  test "includes Auditable concern" do
    assert Transaction.include?(Auditable)
  end

  test "creates audit log on create" do
    assert_difference "AuditLog.count", 1 do
      Transaction.create!(
        organization: @organization,
        client: @client,
        transaction_date: Date.current,
        transaction_type: "PURCHASE"
      )
    end

    audit_log = AuditLog.last
    assert_equal "create", audit_log.action
    assert_equal "Transaction", audit_log.auditable_type
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert Transaction.include?(AmsfConstants)
  end
end
