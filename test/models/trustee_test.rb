# frozen_string_literal: true

require "test_helper"

class TrusteeTest < ActiveSupport::TestCase
  setup do
    @trust_client = clients(:trust)
    @trustee = trustees(:trust_trustee)
  end

  # === Validations ===

  test "valid trustee" do
    assert @trustee.valid?
  end

  test "requires name" do
    @trustee.name = nil
    assert_not @trustee.valid?
    assert_includes @trustee.errors[:name], "can't be blank"
  end

  test "validates nationality format when present" do
    @trustee.nationality = "france"
    assert_not @trustee.valid?
    assert_includes @trustee.errors[:nationality], "must be ISO 3166-1 alpha-2 format"
  end

  test "allows blank nationality" do
    @trustee.nationality = nil
    assert @trustee.valid?
  end

  test "accepts valid ISO alpha-2 nationality" do
    @trustee.nationality = "FR"
    assert @trustee.valid?
  end

  test "client must be a trust" do
    natural_person = clients(:natural_person)
    trustee = Trustee.new(client: natural_person, name: "Invalid Trustee")
    assert_not trustee.valid?
    assert_includes trustee.errors[:client], "must be a trust"
  end

  test "client can be a trust legal entity" do
    trustee = Trustee.new(client: @trust_client, name: "New Trustee", nationality: "FR")
    assert trustee.valid?
  end

  # === Associations ===

  test "belongs to client" do
    assert_equal @trust_client, @trustee.client
  end

  # === is_professional flag ===

  test "is_professional defaults to false" do
    trustee = Trustee.new(client: @trust_client, name: "Non-Pro Trustee")
    assert_equal false, trustee.is_professional
  end

  test "can be marked as professional" do
    assert @trustee.is_professional?
  end
end
