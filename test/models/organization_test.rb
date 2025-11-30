# frozen_string_literal: true

require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "valid organization with all required attributes" do
    organization = organizations(:one)
    assert organization.valid?
  end

  test "requires name" do
    organization = Organization.new(
      account: accounts(:one),
      rci_number: "NEW12345"
    )
    assert_not organization.valid?
    assert_not_empty organization.errors[:name]
  end

  test "requires rci_number" do
    organization = Organization.new(
      account: accounts(:one),
      name: "Test Agency"
    )
    assert_not organization.valid?
    assert_not_empty organization.errors[:rci_number]
  end

  test "validates name maximum length" do
    organization = organizations(:one).dup
    organization.name = "A" * 256
    organization.rci_number = "UNIQUE123"
    assert_not organization.valid?
    assert_not_empty organization.errors[:name]
  end

  test "validates rci_number uniqueness" do
    organization = organizations(:one).dup
    organization.account = accounts(:two)
    assert_not organization.valid?
    assert_not_empty organization.errors[:rci_number]
  end

  test "validates rci_number format is alphanumeric" do
    organization = organizations(:one).dup
    organization.rci_number = "RCI-123-ABC"  # Contains hyphens
    assert_not organization.valid?
    assert_not_empty organization.errors[:rci_number]
  end

  test "allows various alphanumeric rci_number formats" do
    valid_formats = %w[RCI12345 ABC123 12345 RCIABC abc123]
    valid_formats.each_with_index do |format, index|
      organization = Organization.new(
        account: accounts(:two),  # Use account without existing org with conflicting RCI
        name: "Test Agency #{index}",
        rci_number: "UNIQUE#{format}#{index}"  # Ensure uniqueness
      )
      # Only check the format validation, not uniqueness
      organization.valid?
      assert_empty organization.errors[:rci_number].select { |e| e.include?("alphanumeric") },
        "Expected #{format} format to be valid"
    end
  end

  test "validates country length is exactly 2 characters" do
    organization = organizations(:one).dup
    organization.rci_number = "UNIQUE456"
    organization.country = "MCO"  # 3 characters
    assert_not organization.valid?
    assert_not_empty organization.errors[:country]
  end

  test "allows blank country" do
    organization = Organization.new(
      account: accounts(:company),  # Use account without existing organization
      name: "Test Agency",
      rci_number: "BLANKCTRY123"
    )
    assert organization.valid?, "Expected blank country to be valid: #{organization.errors.full_messages}"
  end

  test "allows two-character country code" do
    organization = Organization.new(
      account: accounts(:company),  # Use account without existing organization
      name: "Test Agency",
      rci_number: "CTRYTEST123",
      country: "FR"
    )
    assert organization.valid?, "Expected FR country to be valid: #{organization.errors.full_messages}"
  end

  test "belongs to account" do
    organization = organizations(:one)
    assert_equal accounts(:one), organization.account
  end

  test "includes AmsfConstants" do
    assert Organization.include?(AmsfConstants)
    assert_equal %w[PP PM TRUST], Organization::CLIENT_TYPES
  end

  test "by_country scope filters correctly" do
    mc_orgs = Organization.by_country("MC")
    assert mc_orgs.include?(organizations(:one))
    assert mc_orgs.include?(organizations(:two))
  end
end
