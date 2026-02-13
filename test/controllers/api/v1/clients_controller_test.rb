# frozen_string_literal: true

require "test_helper"

class Api::V1::ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @account = accounts(:one)
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @token = api_tokens(:one).token
    @headers = { "Authorization" => "token #{@token}", "Content-Type" => "application/json" }
  end

  # === Authentication ===

  test "returns 401 without token" do
    get api_v1_clients_path, as: :json
    assert_response :unauthorized
  end

  # === Index ===

  test "lists clients" do
    get api_v1_clients_path, headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_kind_of Array, data
    assert data.any? { |c| c["id"] == @client.id }
  end

  test "filters clients by risk level" do
    get api_v1_clients_path, headers: @headers, params: { risk_level: "HIGH" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.all? { |c| c["risk_level"] == "HIGH" }
  end

  test "filters clients by type" do
    get api_v1_clients_path, headers: @headers, params: { client_type: "NATURAL_PERSON" }, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.all? { |c| c["client_type"] == "NATURAL_PERSON" }
  end

  # === Show ===

  test "shows client details" do
    get api_v1_client_path(@client), headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal @client.name, data["name"]
  end

  test "returns 404 for client from other organization" do
    other_client = clients(:other_org_client)
    get api_v1_client_path(other_client), headers: @headers, as: :json
    assert_response :not_found
  end

  # === Create ===

  test "creates a client" do
    assert_difference "Client.count", 1 do
      post api_v1_clients_path, headers: @headers, params: {
        client: { name: "API Client", client_type: "NATURAL_PERSON" }
      }.to_json, as: :json
    end

    assert_response :created
    data = JSON.parse(response.body)
    assert_equal "API Client", data["name"]
  end

  test "returns errors for invalid client" do
    post api_v1_clients_path, headers: @headers, params: {
      client: { name: "", client_type: "NATURAL_PERSON" }
    }.to_json, as: :json

    assert_response :unprocessable_entity
    data = JSON.parse(response.body)
    assert data["errors"].any?
  end

  # === Onboard ===

  test "onboards client with beneficial owners" do
    assert_difference ["Client.count", "BeneficialOwner.count"], 1 do
      post onboard_api_v1_clients_path, headers: @headers, params: {
        client: { name: "Onboard Corp", client_type: "LEGAL_ENTITY", legal_person_type: "SA" },
        beneficial_owners: [
          { name: "Owner 1", ownership_percentage: 100, control_type: "DIRECT" }
        ]
      }.to_json, as: :json
    end

    assert_response :created
    data = JSON.parse(response.body)
    assert_equal "Onboard Corp", data["name"]
    assert data["beneficial_owners"].any?
  end

  # === Update ===

  test "updates a client" do
    patch api_v1_client_path(@client), headers: @headers, params: {
      client: { name: "Updated via API" }
    }.to_json, as: :json

    assert_response :success
    @client.reload
    assert_equal "Updated via API", @client.name
  end

  # === Delete ===

  test "soft deletes a client" do
    delete api_v1_client_path(@client), headers: @headers, as: :json
    assert_response :no_content

    @client.reload
    assert @client.discarded?
  end

  # === Risk Assessment ===

  test "returns risk assessment for client" do
    get assess_risk_api_v1_client_path(@client), headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("suggested_level")
    assert data.key?("factors")
  end
end
