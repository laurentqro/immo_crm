# frozen_string_literal: true

require "test_helper"

class ServiceResultTest < ActiveSupport::TestCase
  test "success result" do
    result = ServiceResult.success("data")
    assert result.success?
    assert_not result.failure?
    assert_equal "data", result.record
    assert_empty result.errors
  end

  test "failure result with errors" do
    result = ServiceResult.failure(errors: ["Something went wrong"])
    assert result.failure?
    assert_not result.success?
    assert_equal ["Something went wrong"], result.errors
  end

  test "failure result with record" do
    client = clients(:natural_person)
    result = ServiceResult.failure(record: client, errors: ["Name can't be blank"])
    assert result.failure?
    assert_equal client, result.record
  end

  test "success with nil record" do
    result = ServiceResult.success
    assert result.success?
    assert_nil result.record
  end

  test "from_record with valid record" do
    client = clients(:natural_person)
    result = ServiceResult.from_record(client)
    assert result.success?
    assert_equal client, result.record
  end

  test "from_record with invalid record" do
    client = Client.new # Missing required fields
    client.valid?
    result = ServiceResult.from_record(client)
    assert result.failure?
    assert result.errors.any?
  end
end
