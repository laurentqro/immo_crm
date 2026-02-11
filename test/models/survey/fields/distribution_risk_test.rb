# frozen_string_literal: true

require "test_helper"

class Survey::Fields::DistributionRiskTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!(owner: users(:one), name: "Survey Test Account", personal: false)
    @org = Organization.create!(account: @account, name: "Survey Test Agency", rci_number: "SURVEY001")
    @survey = Survey.new(organization: @org, year: 2025)
  end

  # === Q173: ab3206 — New natural person clients ===

  test "ab3206 returns 0 when no clients exist" do
    assert_equal 0, @survey.send(:ab3206)
  end

  test "ab3206 counts only natural persons with became_client_at in the year" do
    Client.create!(organization: @org, name: "NP New", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 6, 15))
    Client.create!(organization: @org, name: "LE New", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", became_client_at: Date.new(2025, 3, 1))

    assert_equal 1, @survey.send(:ab3206)
  end

  test "ab3206 excludes clients from other years" do
    Client.create!(organization: @org, name: "NP 2024", client_type: "NATURAL_PERSON", became_client_at: Date.new(2024, 12, 31))
    Client.create!(organization: @org, name: "NP 2025", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 6, 1))
    Client.create!(organization: @org, name: "NP 2026", client_type: "NATURAL_PERSON", became_client_at: Date.new(2026, 1, 1))

    assert_equal 1, @survey.send(:ab3206)
  end

  test "ab3206 includes clients on year boundaries" do
    Client.create!(organization: @org, name: "NP Jan1", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 1, 1))
    Client.create!(organization: @org, name: "NP Dec31", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 12, 31))

    assert_equal 2, @survey.send(:ab3206)
  end

  test "ab3206 excludes soft-deleted clients" do
    Client.create!(organization: @org, name: "NP Active", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 6, 1))
    Client.create!(organization: @org, name: "NP Deleted", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 6, 1), deleted_at: Time.current)

    assert_equal 1, @survey.send(:ab3206)
  end

  test "ab3206 excludes clients from other organizations" do
    other_account = Account.create!(owner: users(:two), name: "Other Test Account", personal: false)
    other_org = Organization.create!(account: other_account, name: "Other Agency", rci_number: "OTHER001")
    Client.create!(organization: @org, name: "NP Mine", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 6, 1))
    Client.create!(organization: other_org, name: "NP Theirs", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 6, 1))

    assert_equal 1, @survey.send(:ab3206)
  end

  test "ab3206 excludes clients with nil became_client_at" do
    Client.create!(organization: @org, name: "NP No Date", client_type: "NATURAL_PERSON", became_client_at: nil)

    assert_equal 0, @survey.send(:ab3206)
  end

  # === Q174: ab3207 — New legal entity clients ===

  test "ab3207 returns 0 when no clients exist" do
    assert_equal 0, @survey.send(:ab3207)
  end

  test "ab3207 counts only legal entities with became_client_at in the year" do
    Client.create!(organization: @org, name: "LE New", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", became_client_at: Date.new(2025, 4, 10))
    Client.create!(organization: @org, name: "NP New", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 4, 10))

    assert_equal 1, @survey.send(:ab3207)
  end

  test "ab3207 excludes trusts (counted separately in Q175)" do
    Client.create!(organization: @org, name: "LE SARL", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", became_client_at: Date.new(2025, 3, 1))
    Client.create!(organization: @org, name: "LE Trust", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 3, 1))

    assert_equal 1, @survey.send(:ab3207)
  end

  test "ab3207 excludes clients from other years" do
    Client.create!(organization: @org, name: "LE 2024", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", became_client_at: Date.new(2024, 6, 1))
    Client.create!(organization: @org, name: "LE 2025", client_type: "LEGAL_ENTITY", legal_entity_type: "SAM", became_client_at: Date.new(2025, 6, 1))

    assert_equal 1, @survey.send(:ab3207)
  end

  # === Q175: a3208tola — New trust/legal construction clients ===

  test "a3208tola returns 0 when no clients exist" do
    assert_equal 0, @survey.send(:a3208tola)
  end

  test "a3208tola counts only trusts with became_client_at in the year" do
    Client.create!(organization: @org, name: "Trust New", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 7, 1))
    Client.create!(organization: @org, name: "SARL New", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL", became_client_at: Date.new(2025, 7, 1))
    Client.create!(organization: @org, name: "NP New", client_type: "NATURAL_PERSON", became_client_at: Date.new(2025, 7, 1))

    assert_equal 1, @survey.send(:a3208tola)
  end

  test "a3208tola excludes clients from other years" do
    Client.create!(organization: @org, name: "Trust 2024", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2024, 12, 31))
    Client.create!(organization: @org, name: "Trust 2025", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 1, 1))
    Client.create!(organization: @org, name: "Trust 2026", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2026, 1, 1))

    assert_equal 1, @survey.send(:a3208tola)
  end

  test "a3208tola includes trusts on year boundaries" do
    Client.create!(organization: @org, name: "Trust Jan1", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 1, 1))
    Client.create!(organization: @org, name: "Trust Dec31", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 12, 31))

    assert_equal 2, @survey.send(:a3208tola)
  end

  test "a3208tola excludes soft-deleted clients" do
    Client.create!(organization: @org, name: "Trust Active", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 6, 1))
    Client.create!(organization: @org, name: "Trust Deleted", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST", became_client_at: Date.new(2025, 6, 1), deleted_at: Time.current)

    assert_equal 1, @survey.send(:a3208tola)
  end
end
