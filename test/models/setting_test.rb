# frozen_string_literal: true

require "test_helper"

class SettingTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
  end

  # === Validations ===

  test "valid setting with required attributes" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting",
      category: "entity_info"
    )
    assert setting.valid?
  end

  test "requires organization" do
    setting = Setting.new(
      key: "test_setting",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:organization], "must exist"
  end

  test "requires key" do
    setting = Setting.new(
      organization: @organization,
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "requires category" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:category], "can't be blank"
  end

  test "key must be unique within organization" do
    Setting.create!(
      organization: @organization,
      key: "unique_key",
      category: "entity_info"
    )

    duplicate = Setting.new(
      organization: @organization,
      key: "unique_key",
      category: "entity_info"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "same key allowed in different organizations" do
    other_org = organizations(:two)

    Setting.create!(
      organization: @organization,
      key: "shared_key",
      category: "entity_info"
    )

    other_setting = Setting.new(
      organization: other_org,
      key: "shared_key",
      category: "entity_info"
    )
    assert other_setting.valid?
  end

  test "validates category inclusion" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting",
      category: "invalid_category"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:category], "is not included in the list"
  end

  # === Scopes ===

  test "by_category scope filters by category" do
    entity_setting = Setting.create!(
      organization: @organization,
      key: "entity_test",
      category: "entity_info"
    )
    kyc_setting = Setting.create!(
      organization: @organization,
      key: "kyc_test",
      category: "kyc_procedures"
    )

    entity_results = @organization.settings.by_category("entity_info")
    assert_includes entity_results, entity_setting
    assert_not_includes entity_results, kyc_setting
  end

  test "for_organization scope filters by organization" do
    other_org = organizations(:two)
    my_setting = Setting.create!(
      organization: @organization,
      key: "my_setting",
      category: "entity_info"
    )
    other_setting = Setting.create!(
      organization: other_org,
      key: "other_setting",
      category: "entity_info"
    )

    results = Setting.for_organization(@organization)
    assert_includes results, my_setting
    assert_not_includes results, other_setting
  end

  # === Category Constants ===

  test "CATEGORIES constant includes all valid categories" do
    expected = %w[entity_info kyc_procedures compliance_policies training controls]
    assert_equal expected.sort, Setting::CATEGORIES.sort
  end

  # === Association ===

  test "belongs to organization" do
    setting = Setting.new(
      organization: @organization,
      key: "test",
      category: "entity_info"
    )
    assert_equal @organization, setting.organization
  end
end
