# frozen_string_literal: true

require "test_helper"

class Api::V1::ComplianceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @token = api_tokens(:one).token
    @headers = { "Authorization" => "token #{@token}", "Content-Type" => "application/json" }
  end

  test "returns compliance gaps" do
    get api_v1_compliance_gaps_path, headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("gaps")
    assert data.key?("summary")
  end

  test "returns compliance gaps for specific year" do
    get api_v1_compliance_gaps_path, headers: @headers, params: { year: 2024 }, as: :json
    assert_response :success
  end

  test "returns risk assessment" do
    get api_v1_compliance_risk_assessment_path, headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("clients")
    assert data.key?("transactions")
    assert data.key?("str_reports")
    assert data.key?("beneficial_owners")
  end

  test "returns risk assessment for specific year" do
    get api_v1_compliance_risk_assessment_path, headers: @headers, params: { year: 2024 }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal 2024, data["year"]
  end
end
