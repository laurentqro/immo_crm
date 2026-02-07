# frozen_string_literal: true

require "test_helper"

class ArelleClientTest < ActiveSupport::TestCase
  setup do
    @client = ArelleClient.new
  end

  test "validate returns ValidationResult on success" do
    stub_request(:post, "http://localhost:8000/validate")
      .with(body: "<xml/>", headers: { "Content-Type" => "application/xml" })
      .to_return(
        status: 200,
        body: { valid: true, summary: { errors: 0, warnings: 0, info: 1 }, messages: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @client.validate("<xml/>")

    assert result.valid
    assert_equal 0, result.summary[:errors]
    assert_empty result.errors
  end

  test "validate returns errors from response" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: {
          valid: false,
          summary: { errors: 1, warnings: 0, info: 0 },
          messages: [{ severity: "error", code: "test", message: "Test error" }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @client.validate("<xml/>")

    assert_not result.valid
    assert_equal 1, result.errors.length
    assert_equal "Test error", result.error_messages.first
  end

  test "validate raises ConnectionError when service unavailable" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_raise(Errno::ECONNREFUSED)

    assert_raises(ArelleClient::ConnectionError) do
      @client.validate("<xml/>")
    end
  end

  test "available? returns true when service responds" do
    stub_request(:get, "http://localhost:8000/docs")
      .to_return(status: 200)

    assert @client.available?
  end

  test "available? returns false when service unavailable" do
    stub_request(:get, "http://localhost:8000/docs")
      .to_raise(Errno::ECONNREFUSED)

    assert_not @client.available?
  end

  test "available? returns false on HTTP error" do
    stub_request(:get, "http://localhost:8000/docs")
      .to_return(status: 500, body: "Internal Server Error")

    # The ApplicationClient raises InternalError for 500, which available? rescues
    assert_not @client.available?
  end

  test "validate raises error on malformed JSON response" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: "not valid json",
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(ArelleClient::Error) do
      @client.validate("<xml/>")
    end
  end

  test "validate raises error on missing required fields in response" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: { unexpected: "format" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_raises(ArelleClient::Error) do
      @client.validate("<xml/>")
    end
  end

  test "ValidationResult#warnings filters warning messages" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: {
          valid: true,
          summary: { errors: 0, warnings: 2, info: 1 },
          messages: [
            { severity: "warning", code: "w1", message: "Warning 1" },
            { severity: "warning", code: "w2", message: "Warning 2" },
            { severity: "info", code: "i1", message: "Info 1" }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @client.validate("<xml/>")

    assert_equal 2, result.warnings.length
    assert result.warnings.all? { |m| m[:severity] == "warning" }
  end

  test "ValidationResult#valid? predicate method" do
    stub_request(:post, "http://localhost:8000/validate")
      .to_return(
        status: 200,
        body: { valid: true, summary: {}, messages: [] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @client.validate("<xml/>")

    assert result.valid?
  end
end
