require "test_helper"

class MeControllerTest < ActionDispatch::IntegrationTest
  test "returns current user details" do
    get api_v1_me_url, headers: {Authorization: "token #{user.api_tokens.first.token}"}
    assert_response :success

    assert_equal user.name, response.parsed_body["name"]
  end

  test "delete current user" do
    assert_difference "User.count", -1 do
      delete api_v1_me_url, headers: {Authorization: "token #{user.api_tokens.first.token}"}
      assert_response :success
    end
  end

  def user
    @user ||= users(:one)
  end
end
