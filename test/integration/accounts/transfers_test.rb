require "test_helper"

class Jumpstart::AccountsTransferTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:company)
    @admin = users(:one)
    @regular_user = users(:two)
  end

  class AdminUsers < Jumpstart::AccountsTransferTest
    setup do
      sign_in @admin
    end

    test "can transfer account" do
      patch account_transfer_path(@account), params: {user_id: @regular_user.id}
      assert_redirected_to account_path(@account)
      assert_equal @regular_user, @account.reload.owner
    end
  end

  class RegularUsers < Jumpstart::AccountsTransferTest
    setup do
      sign_in @regular_user
    end

    test "cannot transfer account" do
      patch account_transfer_path(@account)
      assert_redirected_to accounts_path
    end
  end
end
