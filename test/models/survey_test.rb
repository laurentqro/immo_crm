# frozen_string_literal: true

require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @year = Date.current.year
    @survey = Survey.new(organization: @organization, year: @year)
  end

  # Q1 — aACTIVE: Active in reporting cycle
  test "aactive returns Oui when organization has transactions in the year" do
    assert @organization.transactions.kept.for_year(@year).exists?,
      "Precondition: organization :one should have transactions in the current year"
    assert_equal "Oui", @survey.aactive
  end

  test "aactive returns Non when organization has no transactions in the year" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_not organizations(:company).transactions.kept.for_year(@year).exists?,
      "Precondition: organization :company should have no transactions in the current year"
    assert_equal "Non", survey.aactive
  end
end
