# frozen_string_literal: true

require "test_helper"

class Clients::OnboardTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  test "onboards client without beneficial owners" do
    result = Clients::Onboard.call(
      organization: @organization,
      client_params: { name: "Simple Client", client_type: "NATURAL_PERSON" }
    )

    assert result.success?
    assert_equal "Simple Client", result.record.name
  end

  test "onboards legal entity with beneficial owners" do
    result = Clients::Onboard.call(
      organization: @organization,
      client_params: { name: "Corp SA", client_type: "LEGAL_ENTITY", legal_person_type: "SA" },
      beneficial_owners: [
        { name: "Owner 1", ownership_percentage: 60, control_type: "DIRECT" },
        { name: "Owner 2", ownership_percentage: 40, control_type: "DIRECT" }
      ]
    )

    assert result.success?
    assert_equal 2, result.record.beneficial_owners.count
    assert_equal "Owner 1", result.record.beneficial_owners.first.name
  end

  test "rolls back when beneficial owner is invalid" do
    initial_client_count = Client.count
    initial_owner_count = BeneficialOwner.count

    result = Clients::Onboard.call(
      organization: @organization,
      client_params: { name: "Corp", client_type: "LEGAL_ENTITY", legal_person_type: "SA" },
      beneficial_owners: [
        { name: "", ownership_percentage: 60 } # Invalid - missing name
      ]
    )

    assert result.failure?
    assert_equal initial_client_count, Client.count
    assert_equal initial_owner_count, BeneficialOwner.count
  end

  test "rejects beneficial owners for natural person" do
    result = Clients::Onboard.call(
      organization: @organization,
      client_params: { name: "Person", client_type: "NATURAL_PERSON" },
      beneficial_owners: [
        { name: "Owner", ownership_percentage: 100 }
      ]
    )

    assert result.failure?
    assert result.errors.any? { |e| e.include?("beneficial owners") }
  end
end
