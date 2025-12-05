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
      value: "test_value",
      value_type: "string",
      category: "entity_info"
    )
    assert setting.valid?
  end

  test "requires organization" do
    setting = Setting.new(
      key: "test_setting",
      value: "test_value",
      value_type: "string",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:organization], "must exist"
  end

  test "requires key" do
    setting = Setting.new(
      organization: @organization,
      value: "test_value",
      value_type: "string",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "requires value_type" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting",
      value: "test_value",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:value_type], "can't be blank"
  end

  test "requires category" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting",
      value: "test_value",
      value_type: "string"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:category], "can't be blank"
  end

  test "key must be unique within organization" do
    Setting.create!(
      organization: @organization,
      key: "unique_key",
      value: "first",
      value_type: "string",
      category: "entity_info"
    )

    duplicate = Setting.new(
      organization: @organization,
      key: "unique_key",
      value: "second",
      value_type: "string",
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
      value: "org_one",
      value_type: "string",
      category: "entity_info"
    )

    other_setting = Setting.new(
      organization: other_org,
      key: "shared_key",
      value: "org_two",
      value_type: "string",
      category: "entity_info"
    )
    assert other_setting.valid?
  end

  test "validates value_type inclusion" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting",
      value: "test_value",
      value_type: "invalid_type",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:value_type], "is not included in the list"
  end

  test "validates category inclusion" do
    setting = Setting.new(
      organization: @organization,
      key: "test_setting",
      value: "test_value",
      value_type: "string",
      category: "invalid_category"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:category], "is not included in the list"
  end

  # === Value Type Casting ===

  test "typed_value returns string for string type" do
    setting = Setting.new(value: "hello", value_type: "string")
    assert_equal "hello", setting.typed_value
  end

  test "typed_value returns integer for integer type" do
    setting = Setting.new(value: "42", value_type: "integer")
    assert_equal 42, setting.typed_value
    assert_kind_of Integer, setting.typed_value
  end

  test "typed_value returns decimal for decimal type" do
    setting = Setting.new(value: "99.95", value_type: "decimal")
    assert_equal BigDecimal("99.95"), setting.typed_value
  end

  test "typed_value returns true for boolean type with true value" do
    setting = Setting.new(value: "true", value_type: "boolean")
    assert_equal true, setting.typed_value
  end

  test "typed_value returns true for boolean type with 1 value" do
    setting = Setting.new(value: "1", value_type: "boolean")
    assert_equal true, setting.typed_value
  end

  test "typed_value returns false for boolean type with false value" do
    setting = Setting.new(value: "false", value_type: "boolean")
    assert_equal false, setting.typed_value
  end

  test "typed_value returns false for boolean type with 0 value" do
    setting = Setting.new(value: "0", value_type: "boolean")
    assert_equal false, setting.typed_value
  end

  test "typed_value returns date for date type" do
    setting = Setting.new(value: "2025-06-15", value_type: "date")
    assert_equal Date.new(2025, 6, 15), setting.typed_value
    assert_kind_of Date, setting.typed_value
  end

  test "typed_value returns nil for nil value" do
    setting = Setting.new(value: nil, value_type: "string")
    assert_nil setting.typed_value
  end

  test "typed_value returns nil for empty string" do
    setting = Setting.new(value: "", value_type: "integer")
    assert_nil setting.typed_value
  end

  # === Type Validation ===

  test "rejects invalid date format" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_date",
      value: "not-a-date",
      value_type: "date",
      category: "training"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:value], "is not a valid date"
  end

  test "rejects malformed date" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_date",
      value: "2025-13-45",
      value_type: "date",
      category: "training"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:value], "is not a valid date"
  end

  test "rejects invalid integer format" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_int",
      value: "abc",
      value_type: "integer",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:value], "is not a valid integer"
  end

  test "rejects invalid decimal format" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_decimal",
      value: "not-a-number",
      value_type: "decimal",
      category: "entity_info"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:value], "is not a valid decimal"
  end

  test "allows valid values for each type" do
    valid_settings = [
      {key: "valid_date", value: "2025-06-15", value_type: "date", category: "training"},
      {key: "valid_int", value: "42", value_type: "integer", category: "entity_info"},
      {key: "valid_decimal", value: "99.95", value_type: "decimal", category: "entity_info"},
      {key: "valid_string", value: "hello", value_type: "string", category: "entity_info"},
      {key: "valid_bool", value: "true", value_type: "boolean", category: "kyc_procedures"}
    ]

    valid_settings.each do |attrs|
      setting = Setting.new(attrs.merge(organization: @organization))
      assert setting.valid?, "Expected #{attrs[:value_type]} value '#{attrs[:value]}' to be valid"
    end
  end

  # === Scopes ===

  test "by_category scope filters by category" do
    entity_setting = Setting.create!(
      organization: @organization,
      key: "entity_test",
      value: "test",
      value_type: "string",
      category: "entity_info"
    )
    kyc_setting = Setting.create!(
      organization: @organization,
      key: "kyc_test",
      value: "test",
      value_type: "string",
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
      value: "mine",
      value_type: "string",
      category: "entity_info"
    )
    other_setting = Setting.create!(
      organization: other_org,
      key: "other_setting",
      value: "theirs",
      value_type: "string",
      category: "entity_info"
    )

    results = Setting.for_organization(@organization)
    assert_includes results, my_setting
    assert_not_includes results, other_setting
  end

  # === XBRL Mapping ===

  test "setting can have xbrl_element" do
    setting = Setting.new(
      organization: @organization,
      key: "xbrl_test_setting",
      value: "true",
      value_type: "boolean",
      category: "kyc_procedures",
      xbrl_element: "a4101"
    )
    assert setting.valid?
    assert_equal "a4101", setting.xbrl_element
  end

  test "xbrl_element is optional" do
    setting = Setting.new(
      organization: @organization,
      key: "internal_note",
      value: "Some note",
      value_type: "string",
      category: "entity_info"
    )
    assert setting.valid?
  end

  test "xbrl_element must match format when present" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_xbrl",
      value: "test",
      value_type: "string",
      category: "entity_info",
      xbrl_element: "invalid"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:xbrl_element], "is invalid"
  end

  test "xbrl_element accepts valid element patterns" do
    valid_elements = %w[a1101 aC1102 a11502B aC1209C a2102BB aC1814W a114 aC168]

    valid_elements.each do |element|
      setting = Setting.new(
        organization: @organization,
        key: "test_#{element}",
        value: "test",
        value_type: "string",
        category: "entity_info",
        xbrl_element: element
      )
      assert setting.valid?, "Expected xbrl_element '#{element}' to be valid"
    end
  end

  test "xbrl_element accepts aACTIVE variants for activity flags" do
    valid_elements = %w[aACTIVE aACTIVERENTALS aACTIVEPS]

    valid_elements.each do |element|
      setting = Setting.new(
        organization: @organization,
        key: "test_#{element.downcase}",
        value: "true",
        value_type: "boolean",
        category: "entity_info",
        xbrl_element: element
      )
      assert setting.valid?, "Expected xbrl_element '#{element}' to be valid"
    end
  end

  test "xbrl_element rejects elements with too few digits" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_xbrl",
      value: "test",
      value_type: "string",
      category: "entity_info",
      xbrl_element: "a12"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:xbrl_element], "is invalid"
  end

  test "xbrl_element rejects elements with too many digits" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_xbrl",
      value: "test",
      value_type: "string",
      category: "entity_info",
      xbrl_element: "a123456"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:xbrl_element], "is invalid"
  end

  test "xbrl_element rejects elements with too many trailing letters" do
    setting = Setting.new(
      organization: @organization,
      key: "bad_xbrl",
      value: "test",
      value_type: "string",
      category: "entity_info",
      xbrl_element: "a1101ABC"
    )
    assert_not setting.valid?
    assert_includes setting.errors[:xbrl_element], "is invalid"
  end

  # === Category Constants ===

  test "CATEGORIES constant includes all valid categories" do
    expected = %w[entity_info kyc_procedures compliance_policies training controls]
    assert_equal expected.sort, Setting::CATEGORIES.sort
  end

  test "VALUE_TYPES constant includes all valid types" do
    expected = %w[boolean integer decimal string date enum]
    assert_equal expected.sort, Setting::VALUE_TYPES.sort
  end

  test "SCHEMA constant includes all setting definitions" do
    assert_kind_of Hash, Setting::SCHEMA
    # 12 entity_info (including activity flags and staffing) + 105 controls = 117 entries
    assert_equal 117, Setting::SCHEMA.keys.count

    # Verify each schema entry has required keys
    Setting::SCHEMA.each do |key, schema|
      assert_includes Setting::VALUE_TYPES, schema[:value_type], "#{key} has invalid value_type"
      assert_includes Setting::CATEGORIES, schema[:category], "#{key} has invalid category"
      # Entity info settings don't require xbrl, controls do
      if schema[:category] == "controls"
        assert schema[:xbrl].present?, "#{key} is missing xbrl element"
      end
    end
  end

  # === Issue #19: New Settings Keys ===

  test "SCHEMA includes activity flags" do
    assert Setting::SCHEMA.key?("activity_sales")
    assert Setting::SCHEMA.key?("activity_rentals")
    assert Setting::SCHEMA.key?("activity_property_management")

    assert_equal "boolean", Setting::SCHEMA["activity_sales"][:value_type]
    assert_equal "aACTIVE", Setting::SCHEMA["activity_sales"][:xbrl]
    assert_equal "aACTIVERENTALS", Setting::SCHEMA["activity_rentals"][:xbrl]
    assert_equal "aACTIVEPS", Setting::SCHEMA["activity_property_management"][:xbrl]
  end

  test "SCHEMA includes staffing keys" do
    assert Setting::SCHEMA.key?("staff_total")
    assert Setting::SCHEMA.key?("staff_compliance")
    assert Setting::SCHEMA.key?("uses_external_compliance")

    assert_equal "integer", Setting::SCHEMA["staff_total"][:value_type]
    assert_equal "integer", Setting::SCHEMA["staff_compliance"][:value_type]
    assert_equal "boolean", Setting::SCHEMA["uses_external_compliance"][:value_type]
    assert_equal "a11006", Setting::SCHEMA["staff_total"][:xbrl]
    assert_equal "aC11502", Setting::SCHEMA["staff_compliance"][:xbrl]
    assert_equal "aC11508", Setting::SCHEMA["uses_external_compliance"][:xbrl]
  end

  test "SCHEMA includes entity identity keys" do
    assert Setting::SCHEMA.key?("entity_legal_form")
    assert Setting::SCHEMA.key?("amsf_registration_number")

    assert_equal "enum", Setting::SCHEMA["entity_legal_form"][:value_type]
    assert_equal "string", Setting::SCHEMA["amsf_registration_number"][:value_type]
  end

  # === Instance Methods ===

  test "boolean? returns true for boolean type" do
    setting = Setting.new(value_type: "boolean")
    assert setting.boolean?
  end

  test "boolean? returns false for non-boolean type" do
    setting = Setting.new(value_type: "string")
    assert_not setting.boolean?
  end

  # === Association ===

  test "belongs to organization" do
    setting = Setting.new(
      organization: @organization,
      key: "test",
      value: "test",
      value_type: "string",
      category: "entity_info"
    )
    assert_equal @organization, setting.organization
  end

  # === Update Value ===

  test "can update value" do
    setting = Setting.create!(
      organization: @organization,
      key: "updatable",
      value: "original",
      value_type: "string",
      category: "entity_info"
    )

    setting.update!(value: "updated")
    assert_equal "updated", setting.reload.value
  end

  test "can update boolean value" do
    setting = Setting.create!(
      organization: @organization,
      key: "toggle",
      value: "false",
      value_type: "boolean",
      category: "kyc_procedures"
    )

    setting.update!(value: "true")
    assert_equal true, setting.reload.typed_value
  end
end
