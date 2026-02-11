# frozen_string_literal: true

require "test_helper"

class SurveyToHashTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @survey = Survey.new(organization: @organization, year: 2025)
  end

  test "to_hash returns hash of field_id to value" do
    result = @survey.to_hash

    assert_kind_of Hash, result
    assert result.key?("a1101"), "Expected hash to include a1101 (total clients)"
  end

  test "to_hash values are strings, numbers, or hashes (dimensional fields)" do
    result = @survey.to_hash

    result.each do |key, value|
      assert [String, Integer, Float, BigDecimal, NilClass, Hash].any? { |t| value.is_a?(t) },
        "Expected #{key} value to be string/number/hash, got #{value.class}"
    end
  end

  test "to_hash includes calculated values" do
    # a1101 is total active (non-discarded) clients
    result = @survey.to_hash

    expected_count = @organization.clients.kept.count
    assert_equal expected_count, result["a1101"]
  end
end
