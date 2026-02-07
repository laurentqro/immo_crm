# frozen_string_literal: true

require "test_helper"

class Compliance::RiskAssessmentTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  test "returns complete assessment structure" do
    result = Compliance::RiskAssessment.call(organization: @organization)

    assert result.success?
    data = result.record
    assert data.key?(:clients)
    assert data.key?(:transactions)
    assert data.key?(:str_reports)
    assert data.key?(:beneficial_owners)
    assert data.key?(:assessed_at)
  end

  test "client summary includes counts by risk level" do
    result = Compliance::RiskAssessment.call(organization: @organization)

    clients = result.record[:clients]
    assert clients[:total] > 0
    assert clients[:by_risk_level].key?(:high)
    assert clients[:by_risk_level].key?(:medium)
    assert clients[:by_risk_level].key?(:low)
  end

  test "client summary includes counts by type" do
    result = Compliance::RiskAssessment.call(organization: @organization)

    clients = result.record[:clients]
    assert clients[:by_type].key?(:natural_persons)
    assert clients[:by_type].key?(:legal_entities)
    assert clients[:by_type].key?(:trusts)
  end

  test "accepts year parameter" do
    result = Compliance::RiskAssessment.call(organization: @organization, year: 2024)

    assert result.success?
    assert_equal 2024, result.record[:year]
  end
end
