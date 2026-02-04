# frozen_string_literal: true

require "test_helper"

class BeneficialOwnerTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    @legal_entity = clients(:legal_entity)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid beneficial owner with required attributes" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont"
    )
    assert owner.valid?
  end

  test "requires name" do
    owner = BeneficialOwner.new(
      client: @legal_entity
    )
    assert_not owner.valid?
    assert_includes owner.errors[:name], "can't be blank"
  end

  test "requires client" do
    owner = BeneficialOwner.new(
      name: "Jean Dupont"
    )
    assert_not owner.valid?
    assert_includes owner.errors[:client], "must exist"
  end

  # === Client Type Validation ===

  test "client must be PM or TRUST type" do
    pp_client = clients(:natural_person)
    owner = BeneficialOwner.new(
      client: pp_client,
      name: "Jean Dupont"
    )
    assert_not owner.valid?
    assert_includes owner.errors[:client], "must be a legal entity (PM) or trust"
  end

  test "accepts PM client" do
    pm_client = clients(:legal_entity)
    owner = BeneficialOwner.new(
      client: pm_client,
      name: "Jean Dupont"
    )
    assert owner.valid?
  end

  test "accepts TRUST client" do
    trust_client = clients(:trust)
    owner = BeneficialOwner.new(
      client: trust_client,
      name: "Jean Dupont"
    )
    assert owner.valid?
  end

  # === Ownership Percentage Validation ===

  test "ownership_percentage can be nil" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      ownership_percentage: nil
    )
    assert owner.valid?
  end

  test "ownership_percentage must be between 0 and 100" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      ownership_percentage: 50.0
    )
    assert owner.valid?
  end

  test "ownership_percentage cannot be negative" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      ownership_percentage: -1
    )
    assert_not owner.valid?
    assert owner.errors[:ownership_percentage].any? { |e| e.include?("greater than or equal to") }
  end

  test "ownership_percentage cannot exceed 100" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      ownership_percentage: 101
    )
    assert_not owner.valid?
    assert owner.errors[:ownership_percentage].any? { |e| e.include?("less than or equal to") }
  end

  test "ownership_percentage allows boundary values" do
    [0, 100, 0.01, 99.99].each do |pct|
      owner = BeneficialOwner.new(
        client: @legal_entity,
        name: "Jean Dupont",
        ownership_percentage: pct
      )
      assert owner.valid?, "Expected ownership_percentage #{pct} to be valid"
    end
  end

  # === Control Type Validation ===

  test "control_type can be nil" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      control_type: nil
    )
    assert owner.valid?
  end

  test "control_type must be valid when present" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      control_type: "INVALID"
    )
    assert_not owner.valid?
    assert_includes owner.errors[:control_type], "is not included in the list"
  end

  test "accepts all valid control_types" do
    %w[DIRECT INDIRECT REPRESENTATIVE].each do |type|
      owner = BeneficialOwner.new(
        client: @legal_entity,
        name: "Jean Dupont",
        control_type: type
      )
      assert owner.valid?, "Expected control_type '#{type}' to be valid"
    end
  end

  # === PEP Validation ===

  test "is_pep defaults to false" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont"
    )
    assert_equal false, owner.is_pep
  end

  test "requires pep_type when is_pep is true" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      is_pep: true
    )
    assert_not owner.valid?
    assert_includes owner.errors[:pep_type], "can't be blank"
  end

  test "pep_type not required when is_pep is false" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      is_pep: false
    )
    assert owner.valid?
  end

  test "pep_type must be valid when present" do
    owner = BeneficialOwner.new(
      client: @legal_entity,
      name: "Jean Dupont",
      is_pep: true,
      pep_type: "INVALID"
    )
    assert_not owner.valid?
    assert_includes owner.errors[:pep_type], "is not included in the list"
  end

  test "accepts all valid pep_types" do
    %w[DOMESTIC FOREIGN INTL_ORG].each do |type|
      owner = BeneficialOwner.new(
        client: @legal_entity,
        name: "Jean Dupont",
        is_pep: true,
        pep_type: type
      )
      assert owner.valid?, "Expected pep_type '#{type}' to be valid"
    end
  end

  # === Associations ===

  test "belongs to client" do
    owner = beneficial_owners(:owner_one)
    assert_instance_of Client, owner.client
  end

  test "can access organization through client" do
    owner = beneficial_owners(:owner_one)
    assert_equal @organization, owner.client.organization
  end

  # === Scopes ===

  test "peps scope returns only PEP beneficial owners" do
    pep_owner = beneficial_owners(:pep_owner)
    regular_owner = beneficial_owners(:owner_one)

    peps = BeneficialOwner.peps
    assert_includes peps, pep_owner
    assert_not_includes peps, regular_owner
  end

  test "for_client scope filters by client" do
    owner = beneficial_owners(:owner_one)
    other_owner = beneficial_owners(:other_client_owner)

    client_owners = BeneficialOwner.for_client(@legal_entity)
    assert_includes client_owners, owner
    assert_not_includes client_owners, other_owner
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert BeneficialOwner.include?(AmsfConstants)
  end

  # === Verification Fields (AMSF Data Capture) ===

  test "source_of_wealth_verified defaults to false" do
    owner = BeneficialOwner.new
    assert_equal false, owner.source_of_wealth_verified
  end

  test "identification_verified defaults to false" do
    owner = BeneficialOwner.new
    assert_equal false, owner.identification_verified
  end

  # === HNWI/UHNWI Derivation Tests ===

  test "hnwis scope returns beneficial owners with net_worth > 5M" do
    hnwi = beneficial_owners(:hnwi_owner)
    uhnwi = beneficial_owners(:uhnwi_owner)
    low_net_worth = beneficial_owners(:low_net_worth_owner)
    at_threshold = beneficial_owners(:at_hnwi_threshold)

    hnwis = BeneficialOwner.hnwis

    assert_includes hnwis, hnwi, "HNWI owner (10M) should be in hnwis scope"
    assert_includes hnwis, uhnwi, "UHNWI owner (75M) should also be in hnwis scope"
    assert_not_includes hnwis, low_net_worth, "Low net worth owner (1M) should not be in hnwis scope"
    assert_not_includes hnwis, at_threshold, "Owner at exactly 5M threshold should not be HNWI (must be > 5M)"
  end

  test "uhnwis scope returns beneficial owners with net_worth > 50M" do
    hnwi = beneficial_owners(:hnwi_owner)
    uhnwi = beneficial_owners(:uhnwi_owner)
    at_uhnwi_threshold = beneficial_owners(:at_uhnwi_threshold)

    uhnwis = BeneficialOwner.uhnwis

    assert_includes uhnwis, uhnwi, "UHNWI owner (75M) should be in uhnwis scope"
    assert_not_includes uhnwis, hnwi, "HNWI owner (10M) should not be in uhnwis scope"
    assert_not_includes uhnwis, at_uhnwi_threshold, "Owner at exactly 50M threshold should not be UHNWI (must be > 50M)"
  end

  test "uhnwi is always a subset of hnwi" do
    # This is the critical AMSF validation rule:
    # Any country in a11206B (HNWI) child (a112012B, UHNWI) must also be in the parent
    uhnwis = BeneficialOwner.uhnwis
    hnwis = BeneficialOwner.hnwis

    # Every UHNWI must also be an HNWI
    uhnwis.each do |uhnwi|
      assert_includes hnwis, uhnwi, "UHNWI #{uhnwi.name} must also be an HNWI"
    end
  end

  test "hnwi? instance method returns true for net_worth > 5M" do
    hnwi = beneficial_owners(:hnwi_owner)
    uhnwi = beneficial_owners(:uhnwi_owner)
    low = beneficial_owners(:low_net_worth_owner)

    assert hnwi.hnwi?, "Owner with 10M should be HNWI"
    assert uhnwi.hnwi?, "Owner with 75M should also be HNWI"
    assert_not low.hnwi?, "Owner with 1M should not be HNWI"
  end

  test "uhnwi? instance method returns true for net_worth > 50M" do
    hnwi = beneficial_owners(:hnwi_owner)
    uhnwi = beneficial_owners(:uhnwi_owner)

    assert uhnwi.uhnwi?, "Owner with 75M should be UHNWI"
    assert_not hnwi.uhnwi?, "Owner with 10M should not be UHNWI"
  end

  test "nil net_worth is neither HNWI nor UHNWI" do
    minimal = beneficial_owners(:minimal_owner)

    assert_nil minimal.net_worth_eur
    assert_not minimal.hnwi?, "Owner with nil net_worth should not be HNWI"
    assert_not minimal.uhnwi?, "Owner with nil net_worth should not be UHNWI"
  end

  test "hnwi and uhnwi thresholds are correct" do
    assert_equal 5_000_000, BeneficialOwner::HNWI_THRESHOLD
    assert_equal 50_000_000, BeneficialOwner::UHNWI_THRESHOLD
  end

  test "boundary values for HNWI classification" do
    # Just below threshold - not HNWI
    owner = BeneficialOwner.new(client: @legal_entity, name: "Test", net_worth_eur: 4_999_999.99)
    assert_not owner.hnwi?

    # Exactly at threshold - not HNWI (must be greater than)
    owner.net_worth_eur = 5_000_000
    assert_not owner.hnwi?

    # Just above threshold - is HNWI
    owner.net_worth_eur = 5_000_000.01
    assert owner.hnwi?
  end

  test "boundary values for UHNWI classification" do
    # Just below threshold - not UHNWI
    owner = BeneficialOwner.new(client: @legal_entity, name: "Test", net_worth_eur: 49_999_999.99)
    assert_not owner.uhnwi?

    # Exactly at threshold - not UHNWI (must be greater than)
    owner.net_worth_eur = 50_000_000
    assert_not owner.uhnwi?

    # Just above threshold - is UHNWI
    owner.net_worth_eur = 50_000_000.01
    assert owner.uhnwi?
  end
end
