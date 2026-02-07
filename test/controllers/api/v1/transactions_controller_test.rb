# frozen_string_literal: true

require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @transaction = transactions(:purchase)
    @client = clients(:natural_person)
    @token = api_tokens(:one).token
    @headers = { "Authorization" => "token #{@token}", "Content-Type" => "application/json" }
  end

  test "lists transactions" do
    get api_v1_transactions_path, headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_kind_of Array, data
  end

  test "shows transaction" do
    get api_v1_transaction_path(@transaction), headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal @transaction.reference, data["reference"]
  end

  test "creates transaction" do
    assert_difference "Transaction.count", 1 do
      post api_v1_transactions_path, headers: @headers, params: {
        transaction: {
          client_id: @client.id,
          transaction_date: Date.current.to_s,
          transaction_type: "PURCHASE",
          payment_method: "WIRE",
          transaction_value: 500000
        }
      }.to_json, as: :json
    end

    assert_response :created
  end

  test "screens transaction for AML flags" do
    get screen_api_v1_transaction_path(@transaction), headers: @headers, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("flags")
    assert data.key?("risk_score")
  end

  test "soft deletes transaction" do
    delete api_v1_transaction_path(@transaction), headers: @headers, as: :json
    assert_response :no_content
  end
end
