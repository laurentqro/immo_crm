# frozen_string_literal: true

require "test_helper"

class Survey::Fields::ControlsTest < ActiveSupport::TestCase
  test "ac1102 returns total_employees_fte setting value" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.settings.create!(key: "total_employees_fte", value: "5", category: "entity_info")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 5, survey.send(:ac1102)
  end

  test "ac1102 returns nil when total_employees_fte setting is not set" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:ac1102)
  end

  # === a3301: Total employees (headcount) ===

  test "a3301 reuses total_employees setting" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.settings.create!(key: "total_employees", value: "12", category: "entity_info")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 12, survey.send(:a3301)
  end

  test "a3301 returns nil when setting is not set" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:a3301)
  end

  # === air328: Is card holder a legal entity? ===

  test "air328 returns setting value" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.settings.create!(key: "card_holder_is_legal_entity", value: "Oui", category: "entity_info")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Oui", survey.send(:air328)
  end

  test "air328 returns nil when setting is not set" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:air328)
  end

  # === a3302: Does entity have branches? (computed from Branch model) ===

  test "a3302 returns Oui when branches exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.branches.create!(name: "Paris Office", country: "FR")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Oui", survey.send(:a3302)
  end

  test "a3302 returns Non when no branches exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:a3302)
  end

  # === a3303: Branches by country (computed from Branch model) ===

  test "a3303 returns branches grouped by country" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.branches.create!(name: "Paris Office", country: "FR")
    org.branches.create!(name: "Lyon Office", country: "FR")
    org.branches.create!(name: "Rome Office", country: "IT")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal({"FR" => 2, "IT" => 1}, survey.send(:a3303))
  end

  test "a3303 returns nil when no branches exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:a3303)
  end

  # === a3306: Foreign branches by country (computed from Branch model) ===

  test "a3306 returns foreign branches grouped by country" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.branches.create!(name: "Paris Office", country: "FR")
    org.branches.create!(name: "Lyon Office", country: "FR")
    org.branches.create!(name: "Rome Office", country: "IT")
    org.branches.create!(name: "Monaco Branch", country: "MC")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal({"FR" => 2, "IT" => 1}, survey.send(:a3306))
  end

  test "a3306 returns nil when no foreign branches exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:a3306)
  end

  test "a3306 excludes domestic branches" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.branches.create!(name: "Monaco Branch", country: "MC")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:a3306)
  end

  # === a3306b: Entity BOs by nationality (computed from EntityBeneficialOwner model) ===

  test "a3306b returns beneficial owners grouped by nationality" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.entity_beneficial_owners.create!(name: "Jean Dupont", nationality: "FR")
    org.entity_beneficial_owners.create!(name: "Pierre Martin", nationality: "MC")
    org.entity_beneficial_owners.create!(name: "Marie Duval", nationality: "MC")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal({"FR" => 1, "MC" => 2}, survey.send(:a3306b))
  end

  test "a3306b returns nil when no entity beneficial owners exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:a3306b)
  end

  # === a3306a: Entity shareholders (25%+) by nationality (computed from EntityShareholder model) ===

  test "a3306a returns shareholders grouped by nationality" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.entity_shareholders.create!(name: "Jean Dupont", nationality: "FR")
    org.entity_shareholders.create!(name: "SCI Monaco", nationality: "MC")
    org.entity_shareholders.create!(name: "Pierre Martin", nationality: "MC")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal({"FR" => 1, "MC" => 2}, survey.send(:a3306a))
  end

  test "a3306a returns nil when no entity shareholders exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:a3306a)
  end

  # === ab1801b: Does entity apply AML risk ratings? ===

  test "ab1801b returns setting value" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.settings.create!(key: "applies_aml_risk_ratings", value: "Oui", category: "entity_info")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Oui", survey.send(:ab1801b)
  end

  test "ab1801b returns nil when setting is not set" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:ab1801b)
  end
end
