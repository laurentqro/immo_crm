# frozen_string_literal: true

require "test_helper"

class ValidationServiceTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    @valid_xbrl = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <xbrl xmlns="http://www.xbrl.org/2003/instance">
        <context id="ctx_entity">
          <entity>
            <identifier scheme="http://www.amsf.mc">12345678</identifier>
          </entity>
          <period>
            <instant>2025-12-31</instant>
          </period>
        </context>
        <unit id="pure">
          <measure>xbrli:pure</measure>
        </unit>
        <strix:a1101 contextRef="ctx_entity" unitRef="pure">42</strix:a1101>
      </xbrl>
    XML

    @service = ValidationService.new(@valid_xbrl)
  end

  # === Initialization ===

  test "initializes with xbrl content" do
    service = ValidationService.new(@valid_xbrl)
    assert_not_nil service
  end

  # === Validation Request ===

  test "validate sends POST request to validator endpoint" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .with(
        body: hash_including("xbrl_content" => @valid_xbrl),
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate
    assert result[:valid]
  end

  test "returns validation result with valid flag" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate
    assert_includes result.keys, :valid
  end

  test "returns errors array" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          errors: [
            { code: "ERR001", message: "Invalid element", element: "a1101" }
          ],
          warnings: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate
    assert_not result[:valid]
    assert_equal 1, result[:errors].length
    assert_equal "ERR001", result[:errors].first[:code]
  end

  test "returns warnings array" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: true,
          errors: [],
          warnings: [
            { code: "WARN001", message: "High cash ratio", element: "a2201" }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate
    assert result[:valid]
    assert_equal 1, result[:warnings].length
    assert_equal "WARN001", result[:warnings].first[:code]
  end

  # === Error Handling ===

  test "handles service unavailable gracefully" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(status: 503, body: "Service Unavailable")

    result = @service.validate
    assert_not result[:valid]
    assert result[:errors].any? { |e| e[:message].include?("unavailable") }
  end

  test "handles connection timeout" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_timeout

    result = @service.validate
    assert_not result[:valid]
    assert result[:errors].any? { |e| e[:message].include?("error") || e[:message].include?("timeout") }
  end

  test "handles connection refused" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_raise(Errno::ECONNREFUSED)

    result = @service.validate
    assert_not result[:valid]
    assert result[:errors].any?
  end

  test "handles malformed JSON response" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: "not valid json",
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate
    assert_not result[:valid]
    assert result[:errors].any?
  end

  test "handles 500 internal server error" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(status: 500, body: "Internal Server Error")

    result = @service.validate
    assert_not result[:valid]
    assert result[:errors].any?
  end

  # === Health Check ===

  test "health check returns true when service is healthy" do
    stub_request(:get, "#{ValidationService::VALIDATOR_URL}/health")
      .to_return(
        status: 200,
        body: { status: "ok" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert ValidationService.healthy?
  end

  test "health check returns false when service is down" do
    stub_request(:get, "#{ValidationService::VALIDATOR_URL}/health")
      .to_return(status: 503)

    assert_not ValidationService.healthy?
  end

  test "health check returns false on connection error" do
    stub_request(:get, "#{ValidationService::VALIDATOR_URL}/health")
      .to_raise(Errno::ECONNREFUSED)

    assert_not ValidationService.healthy?
  end

  # === Configuration ===

  test "uses VALIDATOR_URL from environment" do
    # The constant should be defined
    assert defined?(ValidationService::VALIDATOR_URL)
    assert_kind_of String, ValidationService::VALIDATOR_URL
  end

  test "defaults to localhost:8000 for development" do
    # In test environment, should have a default
    assert_match(/localhost|127\.0\.0\.1/, ValidationService::VALIDATOR_URL)
  end

  # === Validation Result Structure ===

  test "valid result has expected structure" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate

    assert_respond_to result, :[]
    assert_includes result.keys, :valid
    assert_includes result.keys, :errors
    assert_includes result.keys, :warnings
  end

  test "error objects have code message and element" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          errors: [{
            code: "xule:assertion",
            message: "Client count inconsistent",
            element: "a1101"
          }],
          warnings: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate
    error = result[:errors].first

    assert error.key?(:code) || error.key?("code")
    assert error.key?(:message) || error.key?("message")
  end

  # === Retry Logic ===

  test "retries on transient failures" do
    # First call fails, second succeeds
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(status: 503)
      .then
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.validate(retries: 2)
    assert result[:valid]
  end

  test "gives up after max retries" do
    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(status: 503)

    result = @service.validate(retries: 2)
    assert_not result[:valid]
  end

  # === Content Handling ===

  test "sends large XBRL content" do
    large_xbrl = @valid_xbrl * 100  # Repeat to make it larger

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .with(body: hash_including("xbrl_content"))
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = ValidationService.new(large_xbrl)
    result = service.validate
    assert result[:valid]
  end

  test "handles special characters in XBRL" do
    xbrl_with_special = @valid_xbrl.gsub("42", "42 &amp; more <special>")

    stub_request(:post, "#{ValidationService::VALIDATOR_URL}/validate")
      .to_return(
        status: 200,
        body: { valid: true, errors: [], warnings: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = ValidationService.new(xbrl_with_special)
    result = service.validate
    assert_kind_of Hash, result
  end
end
