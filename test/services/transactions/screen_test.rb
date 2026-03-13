# frozen_string_literal: true

require "test_helper"

class Transactions::ScreenTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  test "screens clean transaction as low risk" do
    transaction = transactions(:purchase)
    result = Transactions::Screen.call(transaction: transaction)

    assert result.success?
    assert_equal "LOW", result.record[:risk_score]
    assert_not result.record[:recommend_str]
  end

  test "flags cash transaction above threshold" do
    transaction = transactions(:cash_payment)
    result = Transactions::Screen.call(transaction: transaction)

    assert result.success?
    if transaction.cash_amount.present? && transaction.cash_amount >= 10_000
      assert result.record[:flags].any? { |f| f[:key] == :cash_threshold }
      assert_equal "HIGH", result.record[:risk_score]
      assert result.record[:recommend_str]
    end
  end

  test "always returns screening result" do
    transaction = transactions(:purchase)
    result = Transactions::Screen.call(transaction: transaction)

    assert result.success?
    assert result.record.key?(:transaction_id)
    assert result.record.key?(:flags)
    assert result.record.key?(:risk_score)
    assert result.record.key?(:recommend_str)
    assert result.record.key?(:screened_at)
  end
end
