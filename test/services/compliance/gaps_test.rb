# frozen_string_literal: true

require "test_helper"

class Compliance::GapsTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  test "returns gaps with summary" do
    result = Compliance::Gaps.call(organization: @organization)

    assert result.success?
    assert result.record.key?(:gaps)
    assert result.record.key?(:summary)
    assert result.record[:summary].key?(:total)
    assert result.record[:summary].key?(:critical)
    assert result.record[:summary].key?(:warning)
  end

  test "detects missing settings" do
    result = Compliance::Gaps.call(organization: @organization)

    settings_gaps = result.record[:gaps].select { |g| g[:category] == :settings }
    # Organization :one likely doesn't have all required settings
    assert settings_gaps.any? || @organization.settings.where(key: %w[legal_form staff_total written_aml_policy]).count == 3
  end

  test "accepts year parameter" do
    result = Compliance::Gaps.call(organization: @organization, year: 2024)

    assert result.success?
  end
end
