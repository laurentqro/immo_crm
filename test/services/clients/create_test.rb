# frozen_string_literal: true

require "test_helper"

class Clients::CreateTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  test "creates a valid client" do
    result = Clients::Create.call(
      organization: @organization,
      params: { name: "New Client", client_type: "NATURAL_PERSON" }
    )

    assert result.success?
    assert_equal "New Client", result.record.name
    assert_equal @organization, result.record.organization
  end

  test "returns failure for invalid client" do
    result = Clients::Create.call(
      organization: @organization,
      params: { name: "", client_type: "NATURAL_PERSON" }
    )

    assert result.failure?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  test "creates legal entity with legal_person_type" do
    result = Clients::Create.call(
      organization: @organization,
      params: { name: "Corp", client_type: "LEGAL_ENTITY", legal_person_type: "SARL" }
    )

    assert result.success?
    assert_equal "LEGAL_ENTITY", result.record.client_type
    assert_equal "SARL", result.record.legal_person_type
  end
end
