# frozen_string_literal: true

require "test_helper"

class Survey::Fields::ControlsTest < ActiveSupport::TestCase
  test "ac1102 returns total_employees setting value" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    org.settings.create!(key: "total_employees", value: "5", category: "entity_info")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 5, survey.send(:ac1102)
  end

  test "ac1102 returns nil when total_employees setting is not set" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_nil survey.send(:ac1102)
  end
end
