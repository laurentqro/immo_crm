# frozen_string_literal: true

require "test_helper"

class ManagedPropertyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @client = clients(:natural_person)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)
  end

  # === Basic Validations ===

  test "valid managed_property with required attributes" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo, Monaco",
      management_start_date: Date.new(2024, 1, 1),
      management_fee_percent: 8.0
    )
    assert property.valid?
  end

  test "requires organization" do
    property = ManagedProperty.new(
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0
    )
    assert_not property.valid?
    assert_includes property.errors[:organization], "must exist"
  end

  test "requires client" do
    property = ManagedProperty.new(
      organization: @organization,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0
    )
    assert_not property.valid?
    assert_includes property.errors[:client], "must exist"
  end

  test "requires property_address" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      management_start_date: Date.current,
      management_fee_percent: 8.0
    )
    assert_not property.valid?
    assert_includes property.errors[:property_address], "can't be blank"
  end

  test "requires management_start_date" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_fee_percent: 8.0
    )
    assert_not property.valid?
    assert_includes property.errors[:management_start_date], "can't be blank"
  end

  # === Fee Structure Validation ===

  test "requires either management_fee_percent or management_fee_fixed" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current
    )
    assert_not property.valid?
    assert_includes property.errors[:base], "Either percentage or fixed fee must be specified"
  end

  test "valid with only management_fee_percent" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 10.0
    )
    assert property.valid?
  end

  test "valid with only management_fee_fixed" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_fixed: 500.0
    )
    assert property.valid?
  end

  test "valid with both fee types" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 5.0,
      management_fee_fixed: 200.0
    )
    assert property.valid?
  end

  # === Property Type Validation ===

  test "property_type must be valid when present" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0,
      property_type: "INVALID"
    )
    assert_not property.valid?
    assert_includes property.errors[:property_type], "is not included in the list"
  end

  test "accepts all valid property_types" do
    %w[RESIDENTIAL COMMERCIAL].each do |type|
      property = ManagedProperty.new(
        organization: @organization,
        client: @client,
        property_address: "4 Avenue de Monte-Carlo",
        management_start_date: Date.current,
        management_fee_percent: 8.0,
        property_type: type
      )
      assert property.valid?, "Expected property_type '#{type}' to be valid"
    end
  end

  test "property_type defaults to RESIDENTIAL" do
    property = ManagedProperty.new
    assert_equal "RESIDENTIAL", property.property_type
  end

  # === Tenant Type Validation ===

  test "tenant_type must be valid when present" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0,
      tenant_type: "INVALID"
    )
    assert_not property.valid?
    assert_includes property.errors[:tenant_type], "is not included in the list"
  end

  test "accepts all valid tenant_types" do
    %w[NATURAL_PERSON LEGAL_ENTITY].each do |type|
      property = ManagedProperty.new(
        organization: @organization,
        client: @client,
        property_address: "4 Avenue de Monte-Carlo",
        management_start_date: Date.current,
        management_fee_percent: 8.0,
        tenant_type: type
      )
      assert property.valid?, "Expected tenant_type '#{type}' to be valid"
    end
  end

  test "tenant_type can be blank" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0,
      tenant_type: nil
    )
    assert property.valid?
  end

  # === Country Code Validation ===

  test "tenant_country must be ISO 3166-1 alpha-2 format when present" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0,
      tenant_country: "INVALID"
    )
    assert_not property.valid?
    assert property.errors[:tenant_country].any?
  end

  test "accepts valid ISO country codes" do
    %w[FR MC US GB DE].each do |code|
      property = ManagedProperty.new(
        organization: @organization,
        client: @client,
        property_address: "4 Avenue de Monte-Carlo",
        management_start_date: Date.current,
        management_fee_percent: 8.0,
        tenant_country: code
      )
      assert property.valid?, "Expected tenant_country '#{code}' to be valid"
    end
  end

  test "tenant_country can be blank" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0,
      tenant_country: nil
    )
    assert property.valid?
  end

  # === Numeric Validations ===

  test "monthly_rent must be non-negative when present" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0,
      monthly_rent: -100
    )
    assert_not property.valid?
    assert_includes property.errors[:monthly_rent], "must be greater than or equal to 0"
  end

  test "management_fee_percent must be between 0 and 100" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 150
    )
    assert_not property.valid?
    assert property.errors[:management_fee_percent].any?
  end

  test "management_fee_fixed must be non-negative when present" do
    property = ManagedProperty.new(
      organization: @organization,
      client: @client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_fixed: -50
    )
    assert_not property.valid?
    assert_includes property.errors[:management_fee_fixed], "must be greater than or equal to 0"
  end

  # === Client Organization Validation ===

  test "client must belong to same organization" do
    other_org = organizations(:two)
    other_org_client = clients(:other_org_client)

    property = ManagedProperty.new(
      organization: @organization,
      client: other_org_client,
      property_address: "4 Avenue de Monte-Carlo",
      management_start_date: Date.current,
      management_fee_percent: 8.0
    )
    assert_not property.valid?
    assert_includes property.errors[:client], "must belong to the same organization"
  end

  # === Scopes ===

  test "active scope returns properties without management_end_date" do
    active_property = managed_properties(:active_residential)
    ended_property = managed_properties(:ended_property)

    active = ManagedProperty.active
    assert_includes active, active_property
    assert_not_includes active, ended_property
  end

  test "active_in_year scope returns properties active during year" do
    property = managed_properties(:active_residential)

    active_2024 = ManagedProperty.active_in_year(2024)
    assert_includes active_2024, property
  end

  test "for_organization scope filters by organization" do
    org_one_property = managed_properties(:active_residential)
    org_two_property = managed_properties(:other_org_property)

    org_one_properties = ManagedProperty.for_organization(@organization)
    assert_includes org_one_properties, org_one_property
    assert_not_includes org_one_properties, org_two_property
  end

  # === Associations ===

  test "belongs to organization" do
    property = managed_properties(:active_residential)
    assert_equal @organization, property.organization
  end

  test "belongs to client (landlord)" do
    property = managed_properties(:active_residential)
    assert_respond_to property, :client
    assert_not_nil property.client
  end

  # === AmsfConstants ===

  test "includes AmsfConstants" do
    assert ManagedProperty.include?(AmsfConstants)
  end
end
