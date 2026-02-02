# frozen_string_literal: true

require "test_helper"

class Survey::Fields::CustomerRiskTest < ActiveSupport::TestCase
  test "a1101 counts all clients for the organization" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Client.create!(organization: org, name: "Client 2", client_type: "NATURAL_PERSON")
    Client.create!(organization: org, name: "Client 3", client_type: "LEGAL_ENTITY", legal_person_type: "SARL")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 3, survey.send(:a1101)
  end

  test "aactiveps returns Oui when purchase transactions exist for the year" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 100_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Oui", survey.send(:aactiveps)
  end

  test "aactiveps returns Oui when sale transactions exist for the year" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 100_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Oui", survey.send(:aactiveps)
  end

  test "aactiveps returns Non when only rental transactions exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 10_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:aactiveps)
  end

  test "aactiveps returns Non when no transactions exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:aactiveps)
  end

  test "aactiveps ignores transactions from other years" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2024, 6, 15),
      transaction_value: 100_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:aactiveps)
  end

  test "aactiverentals returns Oui when rental transactions exist for the year" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 10_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Oui", survey.send(:aactiverentals)
  end

  test "aactiverentals returns Non when only purchase/sale transactions exist" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 100_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:aactiverentals)
  end

  test "aactiverentals ignores transactions from other years" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2024, 6, 15),
      transaction_value: 10_000
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:aactiverentals)
  end

  test "aactiverentals returns Non when rental is below 10000 monthly rent" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 9_999
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal "Non", survey.send(:aactiverentals)
  end

  test "a1105b counts transactions BY clients" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")

    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 100_000,
      direction: "BY_CLIENT"
    )
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(2025, 7, 15),
      transaction_value: 200_000,
      direction: "BY_CLIENT"
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 2, survey.send(:a1105b)
  end

  test "a1105b excludes transactions WITH clients" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")

    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 100_000,
      direction: "BY_CLIENT"
    )
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(2025, 7, 15),
      transaction_value: 200_000,
      direction: "WITH_CLIENT"
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 1, survey.send(:a1105b)
  end

  test "a1105b ignores transactions from other years" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")

    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2024, 6, 15),
      transaction_value: 100_000,
      direction: "BY_CLIENT"
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 0, survey.send(:a1105b)
  end

  test "a1105b counts each rental month as a separate transaction for AMSF" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")

    # One purchase = 1 transaction
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 3, 15),
      transaction_value: 500_000,
      direction: "BY_CLIENT"
    )

    # 12-month rental at €15,000/month = 12 transactions for AMSF
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 1, 1),
      transaction_value: 15_000,
      direction: "BY_CLIENT",
      rental_duration_months: 12
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 13, survey.send(:a1105b)
  end

  test "a1105b excludes rental months below 10000 threshold" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    client = Client.create!(organization: org, name: "Client 1", client_type: "NATURAL_PERSON")

    # 12-month rental at €9,000/month = 0 transactions (below threshold)
    Transaction.create!(
      organization: org,
      client: client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 1, 1),
      transaction_value: 9_000,
      direction: "BY_CLIENT",
      rental_duration_months: 12
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 0, survey.send(:a1105b)
  end

  test "a1105b equals sum of a1403b, a1403r, a1502b, a1806tola" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")

    natural_person = Client.create!(organization: org, name: "Natural Person", client_type: "NATURAL_PERSON")
    legal_entity = Client.create!(organization: org, name: "Legal Entity", client_type: "LEGAL_ENTITY", legal_person_type: "SARL")
    trust = Client.create!(organization: org, name: "Trust", client_type: "TRUST")

    # Natural person purchase (a1403b)
    Transaction.create!(
      organization: org,
      client: natural_person,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 3, 15),
      transaction_value: 500_000,
      direction: "BY_CLIENT"
    )

    # Natural person rental (a1403r) - 6 months at €15,000
    Transaction.create!(
      organization: org,
      client: natural_person,
      transaction_type: "RENTAL",
      transaction_date: Date.new(2025, 1, 1),
      transaction_value: 15_000,
      direction: "BY_CLIENT",
      rental_duration_months: 6
    )

    # Legal entity sale (a1502b)
    Transaction.create!(
      organization: org,
      client: legal_entity,
      transaction_type: "SALE",
      transaction_date: Date.new(2025, 5, 15),
      transaction_value: 1_000_000,
      direction: "BY_CLIENT"
    )

    # Trust purchase (a1806tola)
    Transaction.create!(
      organization: org,
      client: trust,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 6, 15),
      transaction_value: 750_000,
      direction: "BY_CLIENT"
    )

    survey = Survey.new(organization: org, year: 2025)

    # AMSF validation: sum of children must equal parent
    children_sum = survey.send(:a1403b) + survey.send(:a1403r) + survey.send(:a1502b) + survey.send(:a1806tola)
    parent = survey.send(:a1105b)

    assert_equal parent, children_sum,
      "Sum of children (#{children_sum}) must equal parent a1105b (#{parent})"
  end

  test "a1105b children fields exclude WITH_CLIENT transactions" do
    org = Organization.create!(account: accounts(:invited), name: "Test Agency", rci_number: "TEST001")
    natural_person = Client.create!(organization: org, name: "Natural Person", client_type: "NATURAL_PERSON")

    # BY_CLIENT transaction - should be counted
    Transaction.create!(
      organization: org,
      client: natural_person,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(2025, 3, 15),
      transaction_value: 500_000,
      direction: "BY_CLIENT"
    )

    # WITH_CLIENT transaction - should NOT be counted
    Transaction.create!(
      organization: org,
      client: natural_person,
      transaction_type: "SALE",
      transaction_date: Date.new(2025, 5, 15),
      transaction_value: 300_000,
      direction: "WITH_CLIENT"
    )

    survey = Survey.new(organization: org, year: 2025)

    assert_equal 1, survey.send(:a1403b), "a1403b should only count BY_CLIENT transactions"
    assert_equal 1, survey.send(:a1105b), "a1105b should only count BY_CLIENT transactions"
  end
end
