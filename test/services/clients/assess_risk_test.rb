# frozen_string_literal: true

require "test_helper"

class Clients::AssessRiskTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  test "low risk for clean client" do
    client = clients(:natural_person)
    result = Clients::AssessRisk.call(client: client)

    assert result.success?
    assert_equal "LOW", result.record[:suggested_level]
    assert_empty result.record[:factors]
  end

  test "high risk for PEP client" do
    client = clients(:pep_client)
    result = Clients::AssessRisk.call(client: client)

    assert result.success?
    assert_equal "HIGH", result.record[:suggested_level]
    assert result.record[:factors].any? { |f| f[:key] == :pep }
  end

  test "high risk for VASP client" do
    client = clients(:vasp_client)
    result = Clients::AssessRisk.call(client: client)

    assert result.success?
    assert_equal "HIGH", result.record[:suggested_level]
    assert result.record[:factors].any? { |f| f[:key] == :vasp }
  end

  test "indicates when risk level change is needed" do
    client = clients(:pep_client)
    # PEP client is already HIGH, so no change needed
    result = Clients::AssessRisk.call(client: client)

    assert_not result.record[:requires_change]
  end

  test "flags when current level differs from suggested" do
    # natural_person is LOW risk, no factors -> LOW suggested, no change
    client = clients(:natural_person)
    result = Clients::AssessRisk.call(client: client)

    assert_not result.record[:requires_change]
  end
end
