require "test_helper"

class HotwireNativeTest < ActionDispatch::IntegrationTest
  test "unauthenticated request redirects to login" do
    get "/account/password"
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated hotwire native requests" do
    get "/account/password", headers: {HTTP_USER_AGENT: "Hotwire Native iOS"}
    assert_response :unauthorized
  end
end
