require "test_helper"

class NotificationTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "creates a notification token" do
    assert_difference "NotificationToken.count" do
      post api_v1_notification_tokens_path, params: {token: "test", platform: "iOS"}
      assert_response :success
    end
  end

  test "deletes a notification token" do
    @user.notification_tokens.create!(token: "test", platform: "iOS")
    assert_difference "NotificationToken.count", -1 do
      delete api_v1_notification_token_path(token: "test")
      assert_response :success
    end
  end

  test "404 deleting a missing token" do
    assert_no_difference "NotificationToken.count" do
      delete api_v1_notification_token_path(token: "missing")
      assert_response :missing
    end
  end
end
