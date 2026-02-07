require "test_helper"

class Jumpstart::SubscriptionsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @plan = plans(:personal)
    @card_token = "tok_visa"
  end

  class AdminUsers < Jumpstart::SubscriptionsTest
    # Applies to personal and team accounts

    setup do
      sign_in @admin
      @account = @admin.personal_account
      Jumpstart::Multitenancy.stub :selected, [] do
        switch_account(@account)
      end
    end

    test "can view billing" do
      Jumpstart.config.stub(:payments_enabled?, true) do
        get billing_path
        assert_response :success
      end
    end

    test "can successfully update a billing email" do
      Jumpstart.config.stub(:payments_enabled?, true) do
        @account.update!(billing_email: nil)
        patch billing_path, params: {account: {billing_email: "accounting@example.com"}}

        assert_response :redirect
        assert_not_nil @account.reload.billing_email
      end
    end

    test "Account can not be subscribed twice" do
      Jumpstart.config.stub(:payments_enabled?, true) do
        @account.set_payment_processor :fake_processor, allow_fake: true
        @account.payment_processor.subscribe
        get checkout_path(plan: @plan)
        assert_redirected_to billing_path
        assert_equal I18n.t("checkouts.already_subscribed"), flash[:alert]
      end
    end

    test "can successfully update a extra billing info" do
      Jumpstart.config.stub(:payments_enabled?, true) do
        patch billing_path, params: {account: {extra_billing_info: "VAT_ID"}}

        assert_response :redirect
        assert_equal "VAT_ID", @account.reload.extra_billing_info
      end
    end
  end

  class RegularUsers < Jumpstart::SubscriptionsTest
    # Regular users on a team account

    setup do
      @regular_user = users(:two)
      sign_in @regular_user
      @account = accounts(:company)
      Jumpstart.config.stub(:account_types, "both") do
        Jumpstart::Multitenancy.stub :selected, [] do
          switch_account(@account)
        end
      end
    end

    test "cannot navigate to new_subscription page" do
      Jumpstart.config.stub(:account_types, "both") do
        Jumpstart.config.stub(:payments_enabled?, true) do
          get checkout_path(plan: @plan)
          assert_redirected_to root_path
          assert_equal I18n.t("must_be_an_admin"), flash[:alert]
        end
      end
    end

    test "cannot subscribe" do
      Jumpstart.config.stub(:account_types, "both") do
        Jumpstart.config.stub(:payments_enabled?, true) do
          post checkout_path, params: {}
          assert_redirected_to root_path
          assert_equal I18n.t("must_be_an_admin"), flash[:alert]
        end
      end
    end

    test "cannot delete subscription" do
      @account.set_payment_processor :fake_processor, allow_fake: true
      subscription = @account.payment_processor.subscribe
      Jumpstart.config.stub(:payments_enabled?, true) do
        delete billing_subscription_cancel_path(subscription)
        assert_redirected_to root_path
        assert_equal I18n.t("must_be_an_admin"), flash[:alert]
      end
    end
  end
end
