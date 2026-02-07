require "test_helper"

class AuthsControllerTest < ActionDispatch::IntegrationTest
  test "returns unauthorized if user not valid" do
    post api_v1_auth_url
    assert_response :unauthorized

    user = users(:one)
    post api_v1_auth_url, params: {email: user.email, password: "invalidpassword"}
    assert_response :unauthorized
  end

  test "returns an api token on successful auth" do
    user = users(:one)
    post api_v1_auth_url, params: {email: user.email, password: UNIQUE_PASSWORD}
    assert_response :success
    assert_not_nil response.parsed_body["token"]
  end

  test "returns 422 if OTP attempt is required but not included" do
    user = users(:one)
    user.enable_two_factor!
    user.set_otp_secret!
    post api_v1_auth_url, params: {email: user.email, password: UNIQUE_PASSWORD}
    assert_response :unprocessable_content
  end

  test "returns unauthorized if OTP attempt is required but incorrect" do
    user = users(:one)
    user.enable_two_factor!
    user.set_otp_secret!
    post api_v1_auth_url, params: {email: user.email, password: UNIQUE_PASSWORD, otp_attempt: "123456"}
    assert_response :unauthorized
  end

  test "returns an api token on successful auth with otp attempt" do
    user = users(:one)
    user.enable_two_factor!
    user.set_otp_secret!
    post api_v1_auth_url, params: {email: user.email, password: UNIQUE_PASSWORD, otp_attempt: user.current_otp}
    assert_response :success
    assert_not_nil response.parsed_body["token"]
  end

  test "creates a new default api token if one didn't exist" do
    user = users(:one)
    assert_difference "user.api_tokens.count" do
      post api_v1_auth_url, params: {email: user.email, password: UNIQUE_PASSWORD}
      assert_response :success
    end
    assert_equal user.api_tokens.find_by(name: ApiToken::DEFAULT_NAME).token, response.parsed_body["token"]
  end

  test "sets auth cookie during hotwire app login" do
    user = users(:one)
    post api_v1_auth_url, params: {email: user.email, password: UNIQUE_PASSWORD}, headers: {HTTP_USER_AGENT: "Turbo Native iOS"}
    assert_response :success

    # Set Devise cookies for Turbo Native apps
    assert_not_nil session["warden.user.user.key"]
  end

  test "destroys notification tokens on sign out" do
    notification_token = notification_tokens(:ios)

    assert_difference "NotificationToken.count", -1 do
      sign_in notification_token.user
      delete api_v1_auth_url, params: {notification_token: notification_token.token}
      assert_response :success
    end
  end

  test "destroy session" do
    sign_in users(:one)
    delete api_v1_auth_url
    assert_response :success
  end
end
