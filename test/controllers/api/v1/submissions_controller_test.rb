# frozen_string_literal: true

require "test_helper"

class Api::V1::SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @token = api_tokens(:one).token
    @headers = { "Authorization" => "token #{@token}", "Content-Type" => "application/json" }
  end

  test "lists submissions" do
    get api_v1_submissions_path, headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "creates submission" do
    # Use a unique year that doesn't conflict with fixtures
    assert_difference "Submission.count", 1 do
      post api_v1_submissions_path, headers: @headers, params: {
        submission: { year: 2099 }
      }.to_json, as: :json
    end

    assert_response :created
  end

  test "previews survey calculations" do
    get preview_api_v1_submissions_path, headers: @headers, params: { year: 2025 }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("fields")
    assert data.key?("completion_percentage")
  end
end
