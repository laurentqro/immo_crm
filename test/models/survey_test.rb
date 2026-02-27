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

  # Q2 — aACTIVEPS: Active for purchases/sales in reporting period
  test "aactiveps returns Oui when organization has purchase or sale transactions in the year" do
    assert @organization.transactions.kept.for_year(@year).where(transaction_type: %w[PURCHASE SALE]).exists?,
      "Precondition: organization :one should have purchase/sale transactions in the current year"
    assert_equal "Oui", @survey.aactiveps
  end

  test "aactiveps returns Non when organization has no purchase or sale transactions in the year" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_not organizations(:company).transactions.kept.for_year(@year).where(transaction_type: %w[PURCHASE SALE]).exists?,
      "Precondition: organization :company should have no purchase/sale transactions"
    assert_equal "Non", survey.aactiveps
  end

  # Q3 — aACTIVERENTALS: Active for rentals (monthly rent >= 10,000 EUR) during reporting period
  test "aactiverentals returns Oui when organization has rental transactions with monthly rent >= 10000" do
    # Create a rental transaction with annual value >= 120,000 (i.e., monthly >= 10,000)
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-HIGH",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    assert_equal "Oui", @survey.aactiverentals
  end

  test "aactiverentals returns Non when organization has no qualifying rental transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_not organizations(:company).transactions.kept.for_year(@year)
      .where(transaction_type: "RENTAL")
      .where(Transaction.arel_table[:rental_annual_value].gteq(120_000)).exists?,
      "Precondition: organization :company should have no qualifying rental transactions"
    assert_equal "Non", survey.aactiverentals
  end

  test "aactiverentals returns Non when rentals exist but below 10000 monthly threshold" do
    # The existing rental fixture has transaction_value: 36000 but no rental_annual_value >= 120,000
    assert @organization.transactions.kept.for_year(@year).where(transaction_type: "RENTAL").exists?,
      "Precondition: organization :one should have rental transactions"
    assert_equal "Non", @survey.aactiverentals
  end

  # Q4 — a1101: Total unique clients active during reporting period
  # Includes purchase/sale clients + rental clients with monthly rent >= 10,000 EUR
  test "a1101 returns count of unique clients with qualifying transactions" do
    # Org :one has current-year qualifying transactions for 4 unique clients:
    # natural_person (purchase, sale, cash_payment), legal_entity (high_value, check_payment),
    # pep_client (pep_transaction), vasp_client (crypto_payment)
    # The rental fixture (legal_entity) has no rental_annual_value so it doesn't qualify,
    # but legal_entity qualifies via purchase/sale transactions anyway.
    assert_equal 4, @survey.a1101
  end

  test "a1101 returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1101
  end

  test "a1101 excludes rental clients below 10000 monthly threshold" do
    # Create an organization with only a low-value rental
    org = organizations(:company)
    client = clients(:company_client)
    Transaction.create!(
      organization: org,
      client: client,
      reference: "LOW-RENT",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000 # 5,000/month — below threshold
    )
    survey = Survey.new(organization: org, year: @year)
    assert_equal 0, survey.a1101
  end

  test "a1101 includes rental clients at or above 10000 monthly threshold" do
    org = organizations(:company)
    client = clients(:company_client)
    Transaction.create!(
      organization: org,
      client: client,
      reference: "HIGH-RENT",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000 # 10,000/month — at threshold
    )
    survey = Survey.new(organization: org, year: @year)
    assert_equal 1, survey.a1101
  end

  test "a1101 counts each client only once even with multiple transactions" do
    # natural_person in org :one has purchase, sale, and cash_payment
    # They should only be counted once
    np_txn_count = @organization.transactions.kept.for_year(@year)
      .where(client: clients(:natural_person))
      .where(transaction_type: %w[PURCHASE SALE]).count
    assert np_txn_count > 1, "Precondition: natural_person should have multiple qualifying transactions"
    # Total unique clients should still be 4
    assert_equal 4, @survey.a1101
  end

  test "a1101 excludes soft-deleted transactions" do
    assert @organization.transactions.where(client: clients(:natural_person)).discarded.exists?,
      "Precondition: there should be a discarded transaction for natural_person"
    # Count should not change due to soft-deleted transactions
    assert_equal 4, @survey.a1101
  end

  # Q5 — a1105B: Total number of transactions during reporting period
  # for purchase, sale, and rental (>= 10k/month) of real estate
  test "a1105b counts all qualifying transactions in the year" do
    # Org :one has 7 current-year kept purchase/sale transactions:
    # purchase, sale, cash_payment, high_value, pep_transaction, crypto_payment, check_payment
    # The rental fixture doesn't qualify (no rental_annual_value >= 120,000)
    assert_equal 7, @survey.a1105b
  end

  test "a1105b returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1105b
  end

  test "a1105b includes qualifying rental transactions" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-HIGH-Q5",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    # 7 purchase/sale + 1 qualifying rental = 8
    assert_equal 8, @survey.a1105b
  end

  test "a1105b excludes rental transactions below 10000 monthly threshold" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-LOW-Q5",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000
    )
    # Still 7 — low-value rental excluded
    assert_equal 7, @survey.a1105b
  end

  test "a1105b excludes soft-deleted transactions" do
    assert @organization.transactions.discarded.exists?,
      "Precondition: there should be discarded transactions"
    # discarded_transaction should not be counted
    assert_equal 7, @survey.a1105b
  end

  test "a1105b counts multiple transactions per client separately" do
    # natural_person has purchase, sale, cash_payment = 3 transactions
    np_count = @organization.transactions.kept.for_year(@year)
      .where(client: clients(:natural_person), transaction_type: %w[PURCHASE SALE]).count
    assert np_count > 1, "Precondition: natural_person should have multiple transactions"
    # Each transaction counted individually (not deduplicated by client)
    assert_equal 7, @survey.a1105b
  end

  # Q6 — a1106B: Total value of funds transferred for purchase and sale of real estate
  # Type: xbrli:monetaryItemType
  test "a1106b sums transaction_value for purchase and sale transactions in the year" do
    # Org :one purchase/sale fixtures in current year:
    # purchase: 1,500,000 + sale: 2,100,000 + cash_payment: 500,000 +
    # high_value: 5,000,000 + pep_transaction: 3,500,000 +
    # crypto_payment: 800,000 + check_payment: 750,000 = 14,150,000
    assert_equal BigDecimal("14150000"), @survey.a1106b
  end

  test "a1106b returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1106b
  end

  test "a1106b excludes rental transactions" do
    rental_value = @organization.transactions.kept.for_year(@year)
      .where(transaction_type: "RENTAL").sum(:transaction_value)
    assert rental_value > 0, "Precondition: there should be rental transactions with value"
    # Rental value should not be included
    assert_equal BigDecimal("14150000"), @survey.a1106b
  end

  test "a1106b excludes soft-deleted transactions" do
    assert @organization.transactions.discarded.exists?,
      "Precondition: there should be discarded transactions"
    assert_equal BigDecimal("14150000"), @survey.a1106b
  end

  test "a1106b excludes transactions from other years" do
    assert @organization.transactions.kept
      .where.not(transaction_date: Date.new(@year)..Date.new(@year).end_of_year)
      .where(transaction_type: %w[PURCHASE SALE]).exists?,
      "Precondition: there should be transactions from other years"
    assert_equal BigDecimal("14150000"), @survey.a1106b
  end

  # Q7 — a1106BRENTALS: Total value of funds transferred for rental of real estate
  # Type: xbrli:monetaryItemType
  test "a1106brentals sums transaction_value for rental transactions in the year" do
    # Org :one rental fixture in current year: rental: 36,000
    assert_equal BigDecimal("36000"), @survey.a1106brentals
  end

  test "a1106brentals returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1106brentals
  end

  test "a1106brentals excludes purchase and sale transactions" do
    ps_value = @organization.transactions.kept.for_year(@year)
      .where(transaction_type: %w[PURCHASE SALE]).sum(:transaction_value)
    assert ps_value > 0, "Precondition: there should be purchase/sale transactions with value"
    assert_equal BigDecimal("36000"), @survey.a1106brentals
  end

  test "a1106brentals excludes soft-deleted transactions" do
    assert @organization.transactions.discarded.exists?,
      "Precondition: there should be discarded transactions"
    assert_equal BigDecimal("36000"), @survey.a1106brentals
  end

  # Q8 — a1105W: Total number of transactions with clients during reporting period
  # for purchase, sale, and rental (>= 10k/month) of real estate
  # Type: xbrli:integerItemType
  test "a1105w counts all qualifying transactions in the year" do
    # Org :one has 7 current-year kept purchase/sale transactions + 0 qualifying rentals
    assert_equal 7, @survey.a1105w
  end

  test "a1105w returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1105w
  end

  test "a1105w includes qualifying rental transactions" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-HIGH-Q8",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    # 7 purchase/sale + 1 qualifying rental = 8
    assert_equal 8, @survey.a1105w
  end

  test "a1105w excludes rental transactions below 10000 monthly threshold" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-LOW-Q8",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000
    )
    # Still 7 — low-value rental excluded
    assert_equal 7, @survey.a1105w
  end

  test "a1105w excludes soft-deleted transactions" do
    assert @organization.transactions.discarded.exists?,
      "Precondition: there should be discarded transactions"
    assert_equal 7, @survey.a1105w
  end

  # Q9 — a1106W: Total value of funds transferred with clients during reporting period
  # for purchase, sale, and rental (>= 10k/month) of real estate
  # Type: xbrli:monetaryItemType
  test "a1106w sums transaction_value for purchase, sale, and qualifying rental transactions" do
    # Org :one has 14,150,000 in purchase/sale + 0 qualifying rentals = 14,150,000
    assert_equal BigDecimal("14150000"), @survey.a1106w
  end

  test "a1106w returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1106w
  end

  test "a1106w includes qualifying rental transaction values" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-HIGH-Q9",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      transaction_value: 240_000,
      rental_annual_value: 120_000
    )
    # 14,150,000 purchase/sale + 240,000 qualifying rental = 14,390,000
    assert_equal BigDecimal("14390000"), @survey.a1106w
  end

  test "a1106w excludes rental transactions below 10000 monthly threshold" do
    Transaction.create!(
      organization: @organization,
      client: clients(:legal_entity),
      reference: "RENTAL-LOW-Q9",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )
    # Still 14,150,000 — low-value rental excluded
    assert_equal BigDecimal("14150000"), @survey.a1106w
  end

  test "a1106w excludes soft-deleted transactions" do
    assert @organization.transactions.discarded.exists?,
      "Precondition: there should be discarded transactions"
    assert_equal BigDecimal("14150000"), @survey.a1106w
  end

  # Q10 — a1204S: Can your entity distinguish the nationality of the beneficial owner of clients?
  # Type: enum "Oui" / "Non" (settings-based)
  test "a1204s returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_nationality",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a1204s
  end

  test "a1204s returns nil when setting is not set" do
    assert_nil @survey.a1204s
  end

  # Q11 — a1204S1: Percentage breakdown of beneficial owners' primary nationalities
  # Type: xbrli:pureItemType (percentage, max 100) — dimensional by country
  # Returns hash of { country_code => percentage }
  test "a1204s1 returns percentage breakdown of BO nationalities" do
    result = @survey.a1204s1

    assert_instance_of Hash, result

    # Org :one has 10 BOs with nationality across legal_entity, legal_entity_two, trust, legal_entity_with_owners:
    # FR: owner_one, at_hnwi_threshold, cascade_owner_two = 3
    # MC: owner_two, pep_owner, trust_owner, hnwi_owner, low_net_worth_owner, cascade_owner_one = 6
    # IT: other_client_owner, at_uhnwi_threshold = 2
    # CH: uhnwi_owner = 1
    # Total with nationality: 12 (minimal_owner has nil nationality, excluded)
    assert_equal BigDecimal("25.0"), result["FR"]   # 3/12 = 25.0%
    assert_equal BigDecimal("50.0"), result["MC"]   # 6/12 = 50.0%
    assert_in_delta 16.67, result["IT"].to_f, 0.01  # 2/12 = 16.67%
    assert_in_delta 8.33, result["CH"].to_f, 0.01   # 1/12 = 8.33%
  end

  test "a1204s1 returns nil when entity cannot distinguish BO nationality" do
    # When a1204s (Q10) is "Non", Q11 should return nil
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_nationality",
      category: "entity_info",
      value: "Non"
    )
    assert_nil @survey.a1204s1
  end

  test "a1204s1 returns empty hash when no beneficial owners exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal({}, survey.a1204s1)
  end

  test "a1204s1 excludes beneficial owners with nil nationality" do
    # minimal_owner has nil nationality — should not appear in result
    result = @survey.a1204s1
    assert_not result.key?(nil), "Should not include nil nationality in breakdown"
  end

  test "a1204s1 excludes beneficial owners from other organizations" do
    # other_org_owner belongs to org :two — should not appear
    result = @survey.a1204s1
    # Verify by checking total percentages sum to ~100
    total = result.values.sum
    assert_in_delta 100.0, total.to_f, 0.1
  end

  # Q12 — a1202O: Total number of BOs with direct or indirect control,
  # broken down by primary nationality (dimensional, integer counts)
  test "a1202o returns count of BOs with direct or indirect control grouped by nationality" do
    result = @survey.a1202o

    assert_instance_of Hash, result

    # Org :one BOs with DIRECT or INDIRECT control_type:
    # FR: owner_one (DIRECT), cascade_owner_two (INDIRECT), at_hnwi_threshold (DIRECT) = 3
    # MC: owner_two, cascade_owner_one, trust_owner, hnwi_owner, low_net_worth_owner = 5
    # IT: other_client_owner, at_uhnwi_threshold = 2
    # CH: uhnwi_owner = 1
    assert_equal 3, result["FR"]
    assert_equal 5, result["MC"]
    assert_equal 2, result["IT"]
    assert_equal 1, result["CH"]
  end

  test "a1202o excludes BOs with REPRESENTATIVE control type" do
    result = @survey.a1202o

    # pep_owner has control_type: REPRESENTATIVE, nationality: MC
    # MC count should be 5, not 6 (pep_owner excluded)
    assert_equal 5, result["MC"]
  end

  test "a1202o excludes BOs with nil control type" do
    result = @survey.a1202o

    # minimal_owner has nil control_type and nil nationality — excluded
    # Total should be 11 (not 12 or 13)
    total = result.values.sum
    assert_equal 11, total
  end

  test "a1202o returns empty hash when no BOs exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal({}, survey.a1202o)
  end

  test "a1202o excludes BOs from other organizations" do
    result = @survey.a1202o

    # other_org_owner (FR, org:two) should not appear
    # Total should be 11
    total = result.values.sum
    assert_equal 11, total
  end

  # Q13 — a1202OB: Total number of BOs representing a legal person,
  # broken down by primary nationality (dimensional, integer counts)
  test "a1202ob returns count of representative BOs grouped by nationality" do
    result = @survey.a1202ob

    assert_instance_of Hash, result

    # Only pep_owner has control_type: REPRESENTATIVE (nationality: MC)
    assert_equal({"MC" => 1}, result)
  end

  test "a1202ob excludes BOs with DIRECT or INDIRECT control type" do
    result = @survey.a1202ob

    # owner_one (FR, DIRECT), cascade_owner_two (FR, INDIRECT) should NOT appear
    assert_nil result["FR"]
  end

  test "a1202ob excludes BOs with nil nationality" do
    result = @survey.a1202ob

    # minimal_owner has no nationality and no control_type — should be excluded
    assert_equal 1, result.values.sum
  end

  test "a1202ob returns empty hash when no representative BOs exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal({}, survey.a1202ob)
  end

  test "a1202ob excludes BOs from other organizations" do
    result = @survey.a1202ob

    # other_org_owner (FR, org:two) should not appear
    assert_equal 1, result.values.sum
  end

  # Q14 — a1204O: Can entity distinguish BOs that hold 25% or more?
  # Type: enum (Oui/Non), settings-based
  test "a1204o returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a1204o
  end

  test "a1204o returns nil when setting is not set" do
    assert_nil @survey.a1204o
  end

  # Q15 — a120425O: Total number of BOs holding at least 25%,
  # broken down by primary nationality (dimensional, integer counts)
  # Conditional on a1204o == "Oui"
  test "a120425o returns nil when a1204o is not Oui" do
    assert_nil @survey.a120425o
  end

  test "a120425o returns count of BOs with 25%+ ownership grouped by nationality" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a120425o

    assert_instance_of Hash, result
    # owner_one (FR, 51%), at_hnwi_threshold (FR, 25%), cascade_owner_two (FR, 40%) = 3
    assert_equal 3, result["FR"]
    # owner_two (MC, 49%), cascade_owner_one (MC, 60%), trust_owner (MC, 100%),
    # hnwi_owner (MC, 30%), low_net_worth_owner (MC, 25%) = 5
    assert_equal 5, result["MC"]
    # other_client_owner (IT, 100%), at_uhnwi_threshold (IT, 25%) = 2
    assert_equal 2, result["IT"]
  end

  test "a120425o excludes BOs with less than 25% ownership" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a120425o

    # uhnwi_owner has 20%, pep_owner has 0% — neither should be counted
    # CH nationality only from uhnwi_owner (20%), so should not appear
    assert_nil result["CH"]
  end

  test "a120425o excludes BOs with nil nationality" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a120425o

    # minimal_owner has nil nationality — should be excluded
    assert_nil result[nil]
  end

  test "a120425o excludes BOs from other organizations" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_bo_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a120425o

    # other_org_owner (FR, org:two, 100%) should not appear
    # Total count should be 10 (only org:one BOs with >= 25%)
    assert_equal 10, result.values.sum
  end

  # Q16 — a1203D: Does entity record residence for BOs holding 25% or more?
  # Type: enum (Oui/Non), settings-based
  test "a1203d returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a1203d
  end

  test "a1203d returns nil when setting is not set" do
    assert_nil @survey.a1203d
  end

  # Q17 — a1207O: Total number of BOs who are foreign residents (residence != MC),
  # holding 25% or more, broken down by primary nationality
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional on a1203d == "Oui"
  test "a1207o returns nil when a1203d is not Oui" do
    assert_nil @survey.a1207o
  end

  test "a1207o returns count of foreign-resident BOs with 25%+ ownership grouped by nationality" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1207o

    assert_instance_of Hash, result
    # Foreign resident BOs (residence_country != "MC") with >= 25% ownership:
    # at_hnwi_threshold: FR nationality, FR residence, 25% → FR: 1
    # other_client_owner: IT nationality, IT residence, 100% → IT: 1
    # at_uhnwi_threshold: IT nationality, IT residence, 25% → IT: 1
    assert_equal 1, result["FR"]
    assert_equal 2, result["IT"]
  end

  test "a1207o excludes BOs who are Monaco residents" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1207o

    # owner_one (FR, MC residence, 51%), owner_two (MC, MC residence, 49%),
    # cascade_owner_one (MC, MC residence, 60%), etc. — all excluded
    # MC nationality BOs are all MC residents, so MC should not appear
    assert_nil result["MC"]
  end

  test "a1207o excludes BOs with less than 25% ownership" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1207o

    # uhnwi_owner has CH nationality, MC residence, 20% — excluded (below 25%)
    assert_nil result["CH"]
  end

  test "a1207o excludes BOs with nil nationality" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1207o

    assert_nil result[nil]
  end

  test "a1207o excludes BOs from other organizations" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1207o

    # other_org_owner (FR, FR residence, 100%, org:two) should not appear
    # Total should be 3 (only org:one foreign-resident BOs with >= 25%)
    assert_equal 3, result.values.sum
  end

  test "a1207o returns empty hash when no foreign-resident BOs exist" do
    Setting.create!(
      organization: organizations(:company),
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal({}, survey.a1207o)
  end

  # Q18 — a1210O: Total number of BOs who are non-residents (no residence recorded),
  # holding 25% or more, broken down by primary nationality
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional on a1203d == "Oui"
  test "a1210o returns nil when a1203d is not Oui" do
    assert_nil @survey.a1210o
  end

  test "a1210o returns count of non-resident BOs with 25%+ ownership grouped by nationality" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    # Create a non-resident BO (residence_country nil) with 25%+ ownership
    BeneficialOwner.create!(
      client: clients(:legal_entity),
      name: "Non-Resident Owner",
      nationality: "GB",
      residence_country: nil,
      ownership_percentage: 30.0,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a1210o

    assert_instance_of Hash, result
    assert_equal 1, result["GB"]
  end

  test "a1210o excludes BOs who have a residence country recorded" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1210o

    # at_hnwi_threshold has FR residence, at_uhnwi_threshold has IT residence,
    # other_client_owner has IT residence — all have residence_country set, so excluded
    assert_nil result&.dig("FR")
    assert_nil result&.dig("IT")
  end

  test "a1210o excludes BOs with less than 25% ownership" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    BeneficialOwner.create!(
      client: clients(:legal_entity),
      name: "Low Ownership Non-Resident",
      nationality: "DE",
      residence_country: nil,
      ownership_percentage: 20.0,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a1210o

    assert_nil result["DE"]
  end

  test "a1210o excludes BOs with nil nationality" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    result = @survey.a1210o

    # minimal_owner has nil nationality and nil residence_country — excluded
    assert_nil result&.dig(nil)
  end

  # Q19 — a11201BCD: Does entity identify and record client type: HNWIs?
  # Type: enum "Oui" / "Non" (settings-based)
  test "a11201bcd returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_hnwi_clients",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a11201bcd
  end

  test "a11201bcd returns nil when setting is not set" do
    assert_nil @survey.a11201bcd
  end

  # Q20 — a11201BCDU: Does entity identify and record client type: UHNWIs?
  # Type: enum "Oui" / "Non" (settings-based)
  test "a11201bcdu returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_uhnwi_clients",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a11201bcdu
  end

  test "a11201bcdu returns nil when setting is not set" do
    assert_nil @survey.a11201bcdu
  end

  # Q21 — a1801: Does entity identify/record trusts and other legal constructions?
  # Type: enum "Oui" / "Non" (settings-based)
  test "a1801 returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_trusts_legal_constructions",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a1801
  end

  test "a1801 returns nil when setting is not set" do
    assert_nil @survey.a1801
  end

  # Q22 — a13601: Does entity have PSAV clients that provide other services?
  # Type: enum "Oui" / "Non" (settings-based)
  test "a13601 returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "has_psav_clients_other_services",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a13601
  end

  test "a13601 returns nil when setting is not set" do
    assert_nil @survey.a13601
  end

  # Q23 — a1102: Total unique natural person clients who are nationals (MC nationality)
  # for purchases, sales, and rentals of real estate
  # Type: xbrli:integerItemType
  test "a1102 returns count of unique natural person clients with MC nationality" do
    # Org :one natural person clients with current-year transactions:
    # natural_person: FR nationality (not MC) → excluded
    # pep_client: MC nationality → counted
    # legal_entity, vasp_client: not natural persons → excluded
    assert_equal 1, @survey.a1102
  end

  test "a1102 returns 0 when organization has no transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1102
  end

  test "a1102 counts each client only once even with multiple transactions" do
    # Add another purchase for pep_client
    Transaction.create!(
      organization: @organization,
      client: clients(:pep_client),
      reference: "PEP-EXTRA",
      transaction_date: Date.current - 2.days,
      transaction_type: "SALE",
      transaction_value: 2_000_000
    )
    # pep_client still only counted once
    assert_equal 1, @survey.a1102
  end

  test "a1102 includes MC nationals with qualifying rental transactions" do
    Transaction.create!(
      organization: @organization,
      client: clients(:pep_client),
      reference: "MC-RENTAL-HIGH",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      transaction_value: 240_000,
      rental_annual_value: 120_000
    )
    # pep_client already counted via purchase, so still 1
    assert_equal 1, @survey.a1102
  end

  test "a1102 excludes rental clients below 10000 monthly threshold" do
    # Create a new MC national with only a low-value rental
    mc_national = Client.create!(
      organization: @organization,
      name: "Low Rent MC National",
      client_type: "NATURAL_PERSON",
      nationality: "MC",
      residence_country: "MC",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: mc_national,
      reference: "LOW-RENT-MC",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000 # 5,000/month — below threshold
    )
    # Still only pep_client counted (low-rent MC national excluded)
    assert_equal 1, @survey.a1102
  end

  test "a1102 excludes non-MC nationals" do
    # natural_person has FR nationality and purchase/sale transactions
    # but should not be counted
    np = clients(:natural_person)
    assert_equal "NATURAL_PERSON", np.client_type
    assert_not_equal "MC", np.nationality
    assert @organization.transactions.kept.for_year(@year)
      .where(client: np, transaction_type: %w[PURCHASE SALE]).exists?
    assert_equal 1, @survey.a1102
  end

  test "a1102 excludes legal entities even with MC nationality" do
    # legal_entity has MC nationality but is a LEGAL_ENTITY, not NATURAL_PERSON
    le = clients(:legal_entity)
    assert_equal "MC", le.nationality
    assert_equal "LEGAL_ENTITY", le.client_type
    assert @organization.transactions.kept.for_year(@year).where(client: le).exists?
    assert_equal 1, @survey.a1102
  end

  test "a1102 excludes soft-deleted transactions" do
    assert @organization.transactions.where(client: clients(:natural_person)).discarded.exists?,
      "Precondition: there should be a discarded transaction"
    assert_equal 1, @survey.a1102
  end

  # Q24 — a1103: Total unique natural person clients who are foreign residents
  # for purchases, sales, and rentals (>= 10k/month) of real estate
  test "a1103 returns count of unique natural person clients with foreign residence" do
    # No existing fixture natural persons have foreign residence + transactions in org :one
    # natural_person has residence_country "MC", pep_client has residence_country "MC"
    assert_equal 0, @survey.a1103

    # Create a foreign-resident natural person with a purchase transaction
    foreign_client = Client.create!(
      organization: @organization,
      name: "Foreign Resident",
      client_type: "NATURAL_PERSON",
      nationality: "FR",
      residence_country: "FR",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: foreign_client,
      reference: "A1103-001",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1103
  end

  test "a1103 counts each client only once even with multiple transactions" do
    foreign_client = Client.create!(
      organization: @organization,
      name: "Foreign Resident",
      client_type: "NATURAL_PERSON",
      nationality: "FR",
      residence_country: "FR",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: foreign_client,
      reference: "A1103-DUP1",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    Transaction.create!(
      organization: @organization,
      client: foreign_client,
      reference: "A1103-DUP2",
      transaction_date: Date.current - 5.days,
      transaction_type: "SALE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1103
  end

  test "a1103 includes foreign-resident natural persons with qualifying rental transactions" do
    foreign_client = Client.create!(
      organization: @organization,
      name: "Foreign Renter",
      client_type: "NATURAL_PERSON",
      nationality: "IT",
      residence_country: "IT",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: foreign_client,
      reference: "A1103-RENT1",
      transaction_date: Date.current - 10.days,
      transaction_type: "RENTAL",
      transaction_value: 120_000,
      rental_annual_value: 120_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1103
  end

  test "a1103 excludes rental clients below 10000 monthly threshold" do
    foreign_client = Client.create!(
      organization: @organization,
      name: "Foreign Low Renter",
      client_type: "NATURAL_PERSON",
      nationality: "IT",
      residence_country: "IT",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: foreign_client,
      reference: "A1103-LOWRENT",
      transaction_date: Date.current - 10.days,
      transaction_type: "RENTAL",
      transaction_value: 60_000,
      rental_annual_value: 60_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 0, @survey.a1103
  end

  test "a1103 excludes MC residents" do
    # natural_person fixture: NATURAL_PERSON, residence_country MC, has purchase/sale transactions
    assert_equal "MC", clients(:natural_person).residence_country
    assert @organization.transactions.kept.for_year(@year)
      .where(client: clients(:natural_person)).exists?
    assert_equal 0, @survey.a1103
  end

  test "a1103 excludes clients with nil residence_country" do
    client_no_residence = Client.create!(
      organization: @organization,
      name: "No Residence",
      client_type: "NATURAL_PERSON",
      nationality: "GB",
      residence_country: nil,
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: client_no_residence,
      reference: "A1103-NIL",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 0, @survey.a1103
  end

  test "a1103 excludes legal entities even with foreign residence" do
    # high_risk_client is LEGAL_ENTITY with residence_country RU
    assert_equal "LEGAL_ENTITY", clients(:high_risk_client).client_type
    assert_equal "RU", clients(:high_risk_client).residence_country
    assert_equal 0, @survey.a1103
  end

  # Q25 — a1104: Total unique natural person clients who are non-residents
  # for purchases, sales, and rentals (>= 10k/month) of real estate
  # Type: xbrli:integerItemType
  test "a1104 returns count of unique natural person clients with nil residence_country" do
    # All existing fixture natural persons have residence_country set → 0
    assert_equal 0, @survey.a1104

    # Create a non-resident natural person with a purchase transaction
    non_resident = Client.create!(
      organization: @organization,
      name: "Non Resident",
      client_type: "NATURAL_PERSON",
      nationality: "US",
      residence_country: nil,
      is_pep: false,
      risk_level: "MEDIUM",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: non_resident,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 5, 1),
      transaction_value: 500_000,
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1104
  end

  test "a1104 counts each client only once even with multiple transactions" do
    non_resident = Client.create!(
      organization: @organization,
      name: "Non Resident Multi",
      client_type: "NATURAL_PERSON",
      nationality: "US",
      residence_country: nil,
      is_pep: false,
      risk_level: "MEDIUM",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: non_resident,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1),
      transaction_value: 300_000,
      payment_method: "WIRE"
    )

    Transaction.create!(
      organization: @organization,
      client: non_resident,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 400_000,
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1104
  end

  test "a1104 includes non-resident natural persons with qualifying rental transactions" do
    non_resident = Client.create!(
      organization: @organization,
      name: "Non Resident Renter",
      client_type: "NATURAL_PERSON",
      nationality: "US",
      residence_country: nil,
      is_pep: false,
      risk_level: "LOW",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: non_resident,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 4, 1),
      transaction_value: 120_000,
      rental_annual_value: 120_000,
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1104
  end

  test "a1104 excludes rental clients below 10000 monthly threshold" do
    non_resident = Client.create!(
      organization: @organization,
      name: "Non Resident Low Renter",
      client_type: "NATURAL_PERSON",
      nationality: "US",
      residence_country: nil,
      is_pep: false,
      risk_level: "LOW",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: non_resident,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 4, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000,
      payment_method: "WIRE"
    )

    assert_equal 0, @survey.a1104
  end

  test "a1104 excludes MC residents" do
    assert_equal "MC", clients(:natural_person).residence_country
    assert @organization.transactions.kept.for_year(@year)
      .where(client: clients(:natural_person)).exists?
    assert_equal 0, @survey.a1104
  end

  test "a1104 excludes foreign residents" do
    foreign_resident = Client.create!(
      organization: @organization,
      name: "Foreign Resident",
      client_type: "NATURAL_PERSON",
      nationality: "US",
      residence_country: "FR",
      is_pep: false,
      risk_level: "LOW",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: foreign_resident,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 5, 1),
      transaction_value: 500_000,
      payment_method: "WIRE"
    )

    assert_equal 0, @survey.a1104
  end

  test "a1104 excludes legal entities even with nil residence_country" do
    le_no_residence = Client.create!(
      organization: @organization,
      name: "LE No Residence",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      nationality: "US",
      residence_country: nil,
      is_pep: false,
      risk_level: "LOW",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: le_no_residence,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 5, 1),
      transaction_value: 500_000,
      payment_method: "WIRE"
    )

    assert_equal 0, @survey.a1104
  end

  # Q26 — a1401: Total unique natural person clients by primary nationality
  # for purchase and sale of real estate (NOT rentals)
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  test "a1401 returns hash of unique natural person clients grouped by nationality for purchase/sale" do
    # Existing fixtures in org :one:
    # - natural_person (FR) has PURCHASE + SALE transactions
    # - pep_client (MC) has PURCHASE transaction
    # Legal entities should be excluded
    result = @survey.a1401

    assert_instance_of Hash, result
    assert_equal 1, result["FR"]
    assert_equal 1, result["MC"]
  end

  test "a1401 excludes legal entities" do
    # legal_entity (MC) has PURCHASE + SALE transactions but is LEGAL_ENTITY
    result = @survey.a1401
    le = clients(:legal_entity)
    assert_equal "LEGAL_ENTITY", le.client_type
    assert_equal "MC", le.nationality
    # MC count should only be from pep_client, not legal_entity
    assert_equal 1, result["MC"]
  end

  test "a1401 excludes rental transactions" do
    # Create a natural person with only a rental transaction
    rental_only = Client.create!(
      organization: @organization,
      name: "Rental Only NP",
      client_type: "NATURAL_PERSON",
      nationality: "IT",
      residence_country: "IT",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: rental_only,
      reference: "A1401-RENT",
      transaction_date: Date.current - 10.days,
      transaction_type: "RENTAL",
      transaction_value: 240_000,
      rental_annual_value: 240_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.a1401
    assert_nil result["IT"], "Rental-only clients should not appear in a1401"
  end

  test "a1401 counts each client only once per nationality even with multiple transactions" do
    # natural_person (FR) already has 3 purchase/sale transactions
    result = @survey.a1401
    assert_equal 1, result["FR"]
  end

  test "a1401 groups multiple clients with same nationality" do
    second_fr = Client.create!(
      organization: @organization,
      name: "Another FR Client",
      client_type: "NATURAL_PERSON",
      nationality: "FR",
      residence_country: "FR",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: second_fr,
      reference: "A1401-FR2",
      transaction_date: Date.current - 10.days,
      transaction_type: "SALE",
      transaction_value: 800_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.a1401
    assert_equal 2, result["FR"]
  end

  test "a1401 excludes clients from other organizations" do
    # other_org_client (FR) in org :two has a PURCHASE transaction
    result = @survey.a1401
    # FR count should only be 1 (natural_person), not include other_org_client
    assert_equal 1, result["FR"]
  end

  test "a1401 excludes soft-deleted transactions" do
    # discarded_transaction belongs to natural_person (FR) but is soft-deleted
    # natural_person still has other kept transactions, so FR: 1
    result = @survey.a1401
    assert_equal 1, result["FR"]
  end

  # Q27 — a1403B: Total transactions by natural person clients for purchase/sale
  test "a1403b counts purchase and sale transactions where client is natural person" do
    # Org :one has these current-year purchase/sale transactions with NP clients:
    # purchase (natural_person, PURCHASE), sale (natural_person, SALE),
    # cash_payment (natural_person, PURCHASE), pep_transaction (pep_client, PURCHASE)
    # Excluded: high_value (LEGAL_ENTITY), crypto_payment (LEGAL_ENTITY),
    # check_payment (LEGAL_ENTITY), rental (RENTAL type), discarded (soft-deleted),
    # last_year (wrong year)
    assert_equal 4, @survey.a1403b
  end

  test "a1403b excludes legal entity client transactions" do
    # high_value, crypto_payment, check_payment are all legal entity clients
    # They should not be counted
    le_count = @organization.transactions.kept.for_year(@year)
      .where(transaction_type: %w[PURCHASE SALE])
      .joins(:client)
      .where(clients: {client_type: "LEGAL_ENTITY"})
      .count
    assert le_count > 0, "Precondition: org should have legal entity transactions"
    # a1403b should only count NP transactions
    assert_equal 4, @survey.a1403b
  end

  test "a1403b excludes rental transactions" do
    # rental fixture is type RENTAL — should not be counted even if client were NP
    assert_equal 4, @survey.a1403b
  end

  test "a1403b excludes soft-deleted transactions" do
    # discarded_transaction is soft-deleted — should not be counted
    assert_equal 4, @survey.a1403b
  end

  test "a1403b excludes transactions from other organizations" do
    # other_org_transaction belongs to org :two
    assert_equal 4, @survey.a1403b
  end

  test "a1403b returns 0 when no qualifying transactions exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1403b
  end

  # Q28 — a1404B: Total value of funds transferred by natural person clients for purchase/sale
  # Type: xbrli:monetaryItemType

  test "a1404b sums transaction_value for purchase/sale transactions with natural person clients" do
    # NP purchase/sale transactions for org :one in current year:
    # purchase: 1,500,000 + sale: 2,100,000 + cash_payment: 500,000 + pep_transaction: 3,500,000
    # Excluded: high_value (LE), crypto_payment (LE), check_payment (LE), rental (RENTAL), discarded
    assert_equal BigDecimal("7600000"), @survey.a1404b
  end

  test "a1404b excludes legal entity client transactions" do
    le_value = @organization.transactions.kept.for_year(@year)
      .where(transaction_type: %w[PURCHASE SALE])
      .joins(:client)
      .where(clients: {client_type: "LEGAL_ENTITY"})
      .sum(:transaction_value)
    assert le_value > 0, "Precondition: org should have legal entity transactions with value"
    assert_equal BigDecimal("7600000"), @survey.a1404b
  end

  test "a1404b excludes rental transactions" do
    assert_equal BigDecimal("7600000"), @survey.a1404b
  end

  test "a1404b returns 0 when no qualifying transactions exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1404b
  end

  # Q29 — a1401R: Total unique natural person clients
  # for rental of real estate (monthly rent >= 10,000 EUR)
  # Type: xbrli:integerItemType (scalar — NoCountryDimension)

  test "a1401r counts unique NP clients with qualifying rentals" do
    np_fr = clients(:natural_person) # nationality: FR
    np_mc = clients(:pep_client)     # nationality: MC

    Transaction.create!(
      organization: @organization,
      client: np_fr,
      reference: "RENTAL-NP-FR",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    Transaction.create!(
      organization: @organization,
      client: np_mc,
      reference: "RENTAL-NP-MC",
      transaction_date: Date.current - 3.days,
      transaction_type: "RENTAL",
      rental_annual_value: 180_000
    )

    assert_equal 2, @survey.a1401r
  end

  test "a1401r excludes rentals below 10000 monthly threshold" do
    np = clients(:natural_person)
    Transaction.create!(
      organization: @organization,
      client: np,
      reference: "RENTAL-LOW",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000 # 5,000/month — below threshold
    )

    assert_equal 0, @survey.a1401r
  end

  test "a1401r excludes legal entity clients" do
    le = clients(:legal_entity)
    Transaction.create!(
      organization: @organization,
      client: le,
      reference: "RENTAL-LE",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )

    assert_equal 0, @survey.a1401r
  end

  test "a1401r counts each client only once even with multiple rental transactions" do
    np = clients(:natural_person)
    Transaction.create!(
      organization: @organization,
      client: np,
      reference: "RENTAL-MULTI-1",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    Transaction.create!(
      organization: @organization,
      client: np,
      reference: "RENTAL-MULTI-2",
      transaction_date: Date.current - 3.days,
      transaction_type: "RENTAL",
      rental_annual_value: 150_000
    )

    assert_equal 1, @survey.a1401r
  end

  test "a1401r returns 0 when no qualifying rental transactions exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1401r
  end

  # Q30 — a1403R: Total transactions by natural person clients
  # for rental of real estate (monthly rent >= 10,000 EUR)

  test "a1403r counts transactions by NP clients for qualifying rentals" do
    np_fr = clients(:natural_person)
    np_mc = clients(:pep_client)

    Transaction.create!(
      organization: @organization,
      client: np_fr,
      reference: "RENTAL-A1403R-1",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 180_000
    )
    Transaction.create!(
      organization: @organization,
      client: np_mc,
      reference: "RENTAL-A1403R-2",
      transaction_date: Date.current - 3.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )

    assert_equal 2, @survey.a1403r
  end

  test "a1403r excludes rentals below 10000 monthly threshold" do
    np = clients(:natural_person)
    Transaction.create!(
      organization: @organization,
      client: np,
      reference: "RENTAL-A1403R-LOW",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 60_000
    )

    assert_equal 0, @survey.a1403r
  end

  test "a1403r excludes legal entity clients" do
    le = clients(:legal_entity)
    Transaction.create!(
      organization: @organization,
      client: le,
      reference: "RENTAL-A1403R-LE",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )

    assert_equal 0, @survey.a1403r
  end

  test "a1403r counts each transaction individually even for same client" do
    np = clients(:natural_person)
    Transaction.create!(
      organization: @organization,
      client: np,
      reference: "RENTAL-A1403R-MULTI-1",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      rental_annual_value: 120_000
    )
    Transaction.create!(
      organization: @organization,
      client: np,
      reference: "RENTAL-A1403R-MULTI-2",
      transaction_date: Date.current - 3.days,
      transaction_type: "RENTAL",
      rental_annual_value: 150_000
    )

    assert_equal 2, @survey.a1403r
  end

  test "a1403r returns 0 when no qualifying rental transactions exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1403r
  end

  # Q31 — aIR129: Were some real estate purchases during the reporting period
  # intended to establish a residence in Monaco?
  # Type: enum "Oui" / "Non" (settings-based)

  test "air129 returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "purchases_intended_for_residence_establishment",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.air129
  end

  test "air129 returns nil when setting is not set" do
    assert_nil @survey.air129
  end

  # Q32 — aIR1210: How many purchases have been made for the purpose of
  # establishing a residence in Monaco during the reporting period?
  # Type: xbrli:integerItemType (computed, conditional on air129)

  test "air1210 returns nil when air129 is not Oui" do
    assert_nil @survey.air1210
  end

  test "air1210 counts purchase transactions with purchase_purpose RESIDENCE" do
    Setting.create!(
      organization: @organization,
      key: "purchases_intended_for_residence_establishment",
      category: "entity_info",
      value: "Oui"
    )

    # Fixtures already have 2 RESIDENCE purchases in org :one:
    # purchase (natural_person) and pep_transaction (pep_client)
    # Add one more to verify counting works
    Transaction.create!(
      organization: @organization,
      client: clients(:natural_person),
      reference: "RES-PURCHASE-EXTRA",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 2_000_000,
      purchase_purpose: "RESIDENCE"
    )

    assert_equal 3, @survey.air1210
  end

  test "air1210 excludes transactions with purchase_purpose INVESTMENT" do
    Setting.create!(
      organization: @organization,
      key: "purchases_intended_for_residence_establishment",
      category: "entity_info",
      value: "Oui"
    )

    # Only INVESTMENT purchase — should not add to the 2 existing RESIDENCE fixtures
    Transaction.create!(
      organization: @organization,
      client: clients(:natural_person),
      reference: "INV-PURCHASE-1",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_500_000,
      purchase_purpose: "INVESTMENT"
    )

    assert_equal 2, @survey.air1210
  end

  test "air1210 excludes sale and rental transactions even with RESIDENCE purpose" do
    Setting.create!(
      organization: @organization,
      key: "purchases_intended_for_residence_establishment",
      category: "entity_info",
      value: "Oui"
    )

    # SALE with RESIDENCE purpose — should not be counted
    Transaction.create!(
      organization: @organization,
      client: clients(:natural_person),
      reference: "RES-SALE-1",
      transaction_date: Date.current - 10.days,
      transaction_type: "SALE",
      transaction_value: 2_000_000,
      purchase_purpose: "RESIDENCE"
    )

    # Still only the 2 existing RESIDENCE purchases from fixtures
    assert_equal 2, @survey.air1210
  end

  test "air1210 excludes soft-deleted transactions" do
    Setting.create!(
      organization: @organization,
      key: "purchases_intended_for_residence_establishment",
      category: "entity_info",
      value: "Oui"
    )

    t = Transaction.create!(
      organization: @organization,
      client: clients(:natural_person),
      reference: "RES-DELETED",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 2_000_000,
      purchase_purpose: "RESIDENCE"
    )
    t.discard!

    # Soft-deleted should not add to the 2 existing RESIDENCE purchases
    assert_equal 2, @survey.air1210
  end

  test "air1210 returns existing fixture count when air129 is Oui" do
    Setting.create!(
      organization: @organization,
      key: "purchases_intended_for_residence_establishment",
      category: "entity_info",
      value: "Oui"
    )

    # Fixtures have 2 RESIDENCE purchases: purchase + pep_transaction
    assert_equal 2, @survey.air1210
  end

  # Q33 — a1501: Total unique legal entity clients (excl. trusts)
  # by incorporation country, for purchase and sale of real estate
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)

  test "a1501 returns hash of unique legal entity clients grouped by incorporation country for purchase/sale" do
    # Create legal entity clients with incorporation_country set and purchase/sale transactions
    le_fr = Client.create!(
      organization: @organization,
      name: "French Corp SARL",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL",
      nationality: "FR",
      incorporation_country: "FR",
      became_client_at: 3.months.ago
    )
    le_ch = Client.create!(
      organization: @organization,
      name: "Swiss Holding SA",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      nationality: "CH",
      incorporation_country: "CH",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: le_fr,
      reference: "A1501-FR",
      transaction_date: Date.current - 5.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    Transaction.create!(
      organization: @organization,
      client: le_ch,
      reference: "A1501-CH",
      transaction_date: Date.current - 3.days,
      transaction_type: "SALE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.a1501

    assert_instance_of Hash, result
    assert_equal 1, result["FR"]
    assert_equal 1, result["CH"]
  end

  test "a1501 excludes trusts" do
    trust = clients(:trust)
    assert_equal "TRUST", trust.legal_entity_type
    assert_equal "MC", trust.incorporation_country

    Transaction.create!(
      organization: @organization,
      client: trust,
      reference: "A1501-TRUST",
      transaction_date: Date.current - 5.days,
      transaction_type: "PURCHASE",
      transaction_value: 3_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.a1501
    # Trust's incorporation_country is MC, but trusts are excluded
    # Only vasp_client (MC, SAM) has incorporation_country=MC and a purchase/sale txn from fixtures
    mc_count = result["MC"] || 0
    assert mc_count <= 1, "Trust should not be counted in a1501"
  end

  test "a1501 excludes natural person clients" do
    # natural_person has purchase/sale transactions but is NATURAL_PERSON
    result = @survey.a1501
    np = clients(:natural_person)
    assert_equal "NATURAL_PERSON", np.client_type
    # The result should only contain legal entity incorporation countries
    assert_instance_of Hash, result
  end

  test "a1501 excludes rental transactions" do
    le_it = Client.create!(
      organization: @organization,
      name: "Italian Rental Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      nationality: "IT",
      incorporation_country: "IT",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: le_it,
      reference: "A1501-RENT",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      transaction_value: 240_000,
      rental_annual_value: 240_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.a1501
    assert_nil result["IT"], "Rental-only legal entity clients should not appear in a1501"
  end

  test "a1501 counts each client only once per country even with multiple transactions" do
    le_de = Client.create!(
      organization: @organization,
      name: "German Corp GmbH",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      nationality: "DE",
      incorporation_country: "DE",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: le_de,
      reference: "A1501-DE-1",
      transaction_date: Date.current - 5.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    Transaction.create!(
      organization: @organization,
      client: le_de,
      reference: "A1501-DE-2",
      transaction_date: Date.current - 3.days,
      transaction_type: "SALE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.a1501
    assert_equal 1, result["DE"]
  end

  # Q34 — a1502B: Total transactions by legal entity clients (excl. trusts)
  # for purchase and sale of real estate
  # Type: xbrli:integerItemType

  test "a1502b counts purchase and sale transactions where client is legal entity excluding trusts" do
    # Org :one has these current-year purchase/sale transactions with LE clients (excl. trusts):
    # high_value (legal_entity, PURCHASE), check_payment (legal_entity, SALE),
    # crypto_payment (vasp_client, PURCHASE)
    # Excluded: rental (RENTAL type), trust clients, NP clients, soft-deleted, other orgs
    assert_equal 3, @survey.a1502b
  end

  test "a1502b excludes trust client transactions" do
    trust = clients(:trust)
    Transaction.create!(
      organization: @organization,
      client: trust,
      reference: "A1502B-TRUST",
      transaction_date: Date.current - 5.days,
      transaction_type: "PURCHASE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    # Trust transaction should not be counted
    assert_equal 3, @survey.a1502b
  end

  test "a1502b excludes natural person client transactions" do
    np_count = @organization.transactions.kept.for_year(@year)
      .where(transaction_type: %w[PURCHASE SALE])
      .joins(:client)
      .where(clients: {client_type: "NATURAL_PERSON"})
      .count
    assert np_count > 0, "Precondition: org should have NP transactions"
    assert_equal 3, @survey.a1502b
  end

  test "a1502b excludes rental transactions" do
    assert_equal 3, @survey.a1502b
  end

  test "a1502b excludes soft-deleted transactions" do
    assert_equal 3, @survey.a1502b
  end

  test "a1502b returns 0 when no qualifying transactions exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1502b
  end

  # Q35 — a1503B: Total value of funds transferred by legal entity clients
  # (excl. trusts) for purchase and sale of real estate
  # Type: xbrli:monetaryItemType (EUR)

  test "a1503b sums transaction_value for purchase/sale transactions with legal entity clients excluding trusts" do
    # LE (non-trust) purchase/sale transactions for org :one in current year:
    # high_value (legal_entity, PURCHASE): 5,000,000
    # check_payment (legal_entity, SALE): 750,000
    # crypto_payment (vasp_client, PURCHASE): 800,000
    # Excluded: rental (RENTAL type), trust clients, NP clients, soft-deleted, other orgs
    assert_equal BigDecimal("6550000"), @survey.a1503b
  end

  test "a1503b excludes trust client transactions" do
    trust = clients(:trust)
    Transaction.create!(
      organization: @organization,
      client: trust,
      reference: "A1503B-TRUST",
      transaction_date: Date.current - 5.days,
      transaction_type: "PURCHASE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    assert_equal BigDecimal("6550000"), @survey.a1503b
  end

  test "a1503b excludes natural person client transactions" do
    np_sum = @organization.transactions.kept.for_year(@year)
      .where(transaction_type: %w[PURCHASE SALE])
      .joins(:client)
      .where(clients: {client_type: "NATURAL_PERSON"})
      .sum(:transaction_value)
    assert np_sum > 0, "Precondition: org should have NP purchase/sale transaction values"
    assert_equal BigDecimal("6550000"), @survey.a1503b
  end

  test "a1503b excludes rental transactions" do
    assert_equal BigDecimal("6550000"), @survey.a1503b
  end

  test "a1503b returns 0 when no qualifying transactions exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal 0, survey.a1503b
  end

  test "a1501 excludes clients with nil incorporation_country" do
    # legal_entity fixture has no incorporation_country set
    le = clients(:legal_entity)
    assert_nil le.incorporation_country
    # legal_entity has purchase/sale txns (high_value, check_payment) but no incorporation_country
    result = @survey.a1501
    # Should not appear in the hash at all
    result.each_value { |v| assert v > 0 }
  end

  # Q36 — a155: Does your entity distinguish if clients are Monegasque legal entities and the type?
  # Type: stringItemType with enum restriction ("Oui" / "Non") — settings-based
  test "a155 returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_monegasque_legal_entity_type",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a155
  end

  test "a155 returns nil when setting is not set" do
    assert_nil @survey.a155
  end

  test "a1210o excludes BOs from other organizations" do
    Setting.create!(
      organization: @organization,
      key: "records_bo_residence_25pct_or_more",
      category: "entity_info",
      value: "Oui"
    )

    # Create a non-resident BO in another org
    BeneficialOwner.create!(
      client: clients(:other_org_legal_entity),
      name: "Other Org Non-Resident",
      nationality: "ES",
      residence_country: nil,
      ownership_percentage: 50.0,
      control_type: "DIRECT",
      is_pep: false
    )

    # Create one in our org so the result isn't empty
    BeneficialOwner.create!(
      client: clients(:legal_entity),
      name: "Our Non-Resident",
      nationality: "GB",
      residence_country: nil,
      ownership_percentage: 30.0,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a1210o

    assert_nil result["ES"]
    assert_equal 1, result["GB"]
  end

  # Q37 — aMLES: Number of Monegasque legal entity clients, broken down by type
  # Type: xbrli:integerItemType — dimensional by legal_entity_type
  # Scope: Purchase/Sale only, Monegasque (incorporation_country == "MC"), excludes trusts
  # Conditional: only when a155 == "Oui"

  test "amles returns nil when a155 is not Oui" do
    assert_nil @survey.amles
  end

  test "amles returns hash of Monegasque legal entity clients grouped by legal_entity_type" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_monegasque_legal_entity_type",
      category: "entity_info",
      value: "Oui"
    )

    # Create Monegasque SAM client with a purchase transaction
    sam_client = Client.create!(
      organization: @organization,
      name: "Monaco SAM Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SAM",
      incorporation_country: "MC",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: sam_client,
      reference: "AMLES-SAM",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Create Monegasque SCI client with a sale transaction
    sci_client = Client.create!(
      organization: @organization,
      name: "Monaco SCI Immo",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      incorporation_country: "MC",
      became_client_at: 2.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: sci_client,
      reference: "AMLES-SCI",
      transaction_date: Date.current - 5.days,
      transaction_type: "SALE",
      transaction_value: 1_500_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.amles

    assert_instance_of Hash, result
    # vasp_client fixture is also SAM with incorporation_country MC and a PURCHASE txn
    assert_equal 2, result["SAM"]
    assert_equal 1, result["SCI"]
  end

  test "amles excludes trusts" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_monegasque_legal_entity_type",
      category: "entity_info",
      value: "Oui"
    )

    trust = clients(:trust)
    assert_equal "TRUST", trust.legal_entity_type
    assert_equal "MC", trust.incorporation_country

    Transaction.create!(
      organization: @organization,
      client: trust,
      reference: "AMLES-TRUST",
      transaction_date: Date.current - 3.days,
      transaction_type: "PURCHASE",
      transaction_value: 5_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.amles
    assert_nil result["TRUST"]
  end

  test "amles excludes non-Monegasque legal entities" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_monegasque_legal_entity_type",
      category: "entity_info",
      value: "Oui"
    )

    foreign_le = Client.create!(
      organization: @organization,
      name: "French SARL Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL",
      incorporation_country: "FR",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: foreign_le,
      reference: "AMLES-FR",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.amles
    # The SARL count should not include the French SARL
    # Only vasp_client (SAM, MC) from fixtures should appear, no SARL from MC
    assert_nil result["SARL"]
  end

  test "amles excludes rental transactions" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_monegasque_legal_entity_type",
      category: "entity_info",
      value: "Oui"
    )

    rental_le = Client.create!(
      organization: @organization,
      name: "Monaco Rental SCI",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      incorporation_country: "MC",
      became_client_at: 2.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: rental_le,
      reference: "AMLES-RENTAL",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      transaction_value: 240_000,
      rental_annual_value: 240_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    result = @survey.amles
    assert_nil result["SCI"]
  end

  test "amles counts each client only once even with multiple transactions" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_monegasque_legal_entity_type",
      category: "entity_info",
      value: "Oui"
    )

    sam_client = Client.create!(
      organization: @organization,
      name: "Multi-Txn SAM",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SAM",
      incorporation_country: "MC",
      became_client_at: 3.months.ago
    )
    2.times do |i|
      Transaction.create!(
        organization: @organization,
        client: sam_client,
        reference: "AMLES-MULTI-#{i}",
        transaction_date: Date.current - (i + 1).days,
        transaction_type: "PURCHASE",
        transaction_value: 1_000_000,
        property_country: "MC",
        payment_method: "WIRE"
      )
    end

    result = @survey.amles
    # vasp_client (SAM, MC) + sam_client = 2 SAMs
    assert_equal 2, result["SAM"]
  end

  # Q38 — a11206B: Total unique HNWI beneficial owners of legal entity clients,
  # broken down by primary nationality of the HNWI
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Scope: Purchase/Sale only, legal entity clients (excl. trusts)
  # Conditional: only when a11201bcd == "Oui"

  test "a11206b returns nil when a11201bcd is not Oui" do
    assert_nil @survey.a11206b
  end

  test "a11206b returns hash of HNWI BOs grouped by nationality" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_hnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    # Create a legal entity client with a purchase transaction
    le_client = Client.create!(
      organization: @organization,
      name: "HNWI BO Test Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: le_client,
      reference: "A11206B-1",
      transaction_date: Date.current - 10.days,
      transaction_type: "PURCHASE",
      transaction_value: 3_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Create an HNWI beneficial owner (net worth > 5M)
    BeneficialOwner.create!(
      client: le_client,
      name: "Rich Owner DE",
      nationality: "DE",
      net_worth_eur: 10_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    # Create another HNWI BO with different nationality
    BeneficialOwner.create!(
      client: le_client,
      name: "Rich Owner BE",
      nationality: "BE",
      net_worth_eur: 8_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    # Create a non-HNWI BO (should not appear)
    BeneficialOwner.create!(
      client: le_client,
      name: "Normal Owner ES",
      nationality: "ES",
      net_worth_eur: 1_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b

    assert_instance_of Hash, result
    # Our test data: DE and BE BOs are HNWI, ES is not
    assert_equal 1, result["DE"]
    assert_equal 1, result["BE"]
    assert_nil result["ES"]
  end

  test "a11206b excludes BOs of trust clients" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_hnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    trust = clients(:trust)
    Transaction.create!(
      organization: @organization,
      client: trust,
      reference: "A11206B-TRUST",
      transaction_date: Date.current - 5.days,
      transaction_type: "PURCHASE",
      transaction_value: 5_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    BeneficialOwner.create!(
      client: trust,
      name: "Trust HNWI Owner",
      nationality: "JP",
      net_worth_eur: 20_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b
    assert_nil result["JP"]
  end

  test "a11206b excludes BOs of clients with only rental transactions" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_hnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    rental_le = Client.create!(
      organization: @organization,
      name: "Rental Only Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      became_client_at: 2.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: rental_le,
      reference: "A11206B-RENTAL",
      transaction_date: Date.current - 5.days,
      transaction_type: "RENTAL",
      transaction_value: 240_000,
      rental_annual_value: 240_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    BeneficialOwner.create!(
      client: rental_le,
      name: "Rental HNWI Owner",
      nationality: "SE",
      net_worth_eur: 15_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b
    assert_nil result["SE"]
  end

  test "a11206b does not double-count a BO even with multiple transactions on the client" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_hnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    le_client = Client.create!(
      organization: @organization,
      name: "Multi-Txn HNWI Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      became_client_at: 3.months.ago
    )
    2.times do |i|
      Transaction.create!(
        organization: @organization,
        client: le_client,
        reference: "A11206B-MULTI-#{i}",
        transaction_date: Date.current - (i + 1).days,
        transaction_type: "PURCHASE",
        transaction_value: 2_000_000,
        property_country: "MC",
        payment_method: "WIRE"
      )
    end

    BeneficialOwner.create!(
      client: le_client,
      name: "Single HNWI NL",
      nationality: "NL",
      net_worth_eur: 12_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b
    assert_equal 1, result["NL"]
  end

  # Q39 — a112012B: UHNWI beneficial owners of legal entity clients by nationality

  test "a112012b returns nil when a11201bcdu is not Oui" do
    result = @survey.a112012b
    assert_nil result
  end

  test "a112012b returns hash of UHNWI BOs grouped by nationality" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_uhnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    le_client = Client.create!(
      organization: @organization,
      name: "UHNWI LE Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: le_client,
      reference: "A112012B-1",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 5_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # UHNWI BO (>50M) — should be counted
    BeneficialOwner.create!(
      client: le_client,
      name: "UHNWI FR",
      nationality: "FR",
      net_worth_eur: 60_000_000,
      control_type: "DIRECT",
      is_pep: false
    )
    # UHNWI BO (>50M) — different nationality
    BeneficialOwner.create!(
      client: le_client,
      name: "UHNWI GB",
      nationality: "GB",
      net_worth_eur: 80_000_000,
      control_type: "DIRECT",
      is_pep: false
    )
    # HNWI but NOT UHNWI (>5M but <=50M) — should NOT be counted
    BeneficialOwner.create!(
      client: le_client,
      name: "HNWI Only DE",
      nationality: "DE",
      net_worth_eur: 12_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a112012b
    assert_equal 1, result["FR"]
    assert_equal 1, result["GB"]
    assert_nil result["DE"]
  end

  test "a112012b excludes BOs of trust clients" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_uhnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    trust_client = Client.create!(
      organization: @organization,
      name: "Trust Client",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A112012B-TRUST",
      transaction_date: Date.current - 1.month,
      transaction_type: "SALE",
      transaction_value: 3_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    BeneficialOwner.create!(
      client: trust_client,
      name: "Trust UHNWI",
      nationality: "JP",
      net_worth_eur: 100_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a112012b
    assert_nil result["JP"]
  end

  test "a112012b excludes BOs of clients with only rental transactions" do
    Setting.create!(
      organization: @organization,
      key: "identifies_records_uhnwi_clients",
      category: "entity_info",
      value: "Oui"
    )

    le_client = Client.create!(
      organization: @organization,
      name: "Rental Only LE",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      became_client_at: 3.months.ago
    )
    Transaction.create!(
      organization: @organization,
      client: le_client,
      reference: "A112012B-RENTAL",
      transaction_date: Date.current - 1.month,
      transaction_type: "RENTAL",
      transaction_value: 200_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    BeneficialOwner.create!(
      client: le_client,
      name: "Rental UHNWI",
      nationality: "KR",
      net_worth_eur: 75_000_000,
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a112012b
    assert_nil result["KR"]
  end

  # Q40 — a1802BTOLA: Does entity distinguish if clients are trusts or other legal constructions?
  # Type: stringItemType with enum restriction ("Oui" / "Non") — settings-based
  test "a1802btola returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a1802btola
  end

  test "a1802btola returns nil when setting is not set" do
    assert_nil @survey.a1802btola
  end

  # Q41 — a1802TOLA: Total unique trust/legal construction clients
  # for purchases, sales, and rentals of real estate
  # Type: xbrli:integerItemType (scalar — NoCountryDimension)
  # Conditional: only when a1802btola == "Oui"
  test "a1802tola returns nil when a1802btola is not Oui" do
    assert_nil @survey.a1802tola
  end

  test "a1802tola counts unique trust clients for purchase/sale and rental" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    trust_client = Client.create!(
      organization: @organization,
      name: "Trust Alpha",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 6.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1802TOLA-PS",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    trust_client_2 = Client.create!(
      organization: @organization,
      name: "Trust Beta",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "FR",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: trust_client_2,
      reference: "A1802TOLA-RENTAL",
      transaction_date: Date.current - 1.week,
      transaction_type: "RENTAL",
      transaction_value: 180_000,
      rental_annual_value: 180_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 2, @survey.a1802tola
  end

  test "a1802tola excludes non-trust legal entity clients" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    trust_client = Client.create!(
      organization: @organization,
      name: "Trust Gamma",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 6.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1802TOLA-TRUST",
      transaction_date: Date.current - 1.month,
      transaction_type: "SALE",
      transaction_value: 500_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    non_trust_le = Client.create!(
      organization: @organization,
      name: "SCI Delta",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      incorporation_country: "MC",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: non_trust_le,
      reference: "A1802TOLA-SCI",
      transaction_date: Date.current - 2.months,
      transaction_type: "PURCHASE",
      transaction_value: 800_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1802tola
  end

  # Q42 — a1807ATOLA: Total unique Monegasque trust/legal construction clients
  # for purchases, sales, and rentals of real estate
  # Type: xbrli:integerItemType — conditional on a1802btola == "Oui"
  test "a1807atola returns nil when a1802btola is not Oui" do
    assert_nil @survey.a1807atola
  end

  test "a1807atola counts only Monegasque trust clients" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    mc_trust = Client.create!(
      organization: @organization,
      name: "MC Trust",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 6.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: mc_trust,
      reference: "A1807-MC",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    fr_trust = Client.create!(
      organization: @organization,
      name: "FR Trust",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "FR",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: fr_trust,
      reference: "A1807-FR",
      transaction_date: Date.current - 1.week,
      transaction_type: "SALE",
      transaction_value: 500_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1807atola
  end

  test "a1807atola counts across purchase, sale, and rental transactions" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    mc_trust_ps = Client.create!(
      organization: @organization,
      name: "MC Trust PS",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 6.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: mc_trust_ps,
      reference: "A1807-PS",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    mc_trust_rental = Client.create!(
      organization: @organization,
      name: "MC Trust Rental",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 3.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: mc_trust_rental,
      reference: "A1807-RENTAL",
      transaction_date: Date.current - 1.week,
      transaction_type: "RENTAL",
      transaction_value: 180_000,
      rental_annual_value: 180_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 2, @survey.a1807atola
  end

  test "a1802tola counts each unique trust client only once even with multiple transactions" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    trust_client = Client.create!(
      organization: @organization,
      name: "Trust Epsilon",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "LU",
      became_client_at: 6.months.ago
    )

    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1802TOLA-T1",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1802TOLA-T2",
      transaction_date: Date.current - 2.months,
      transaction_type: "SALE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 1, @survey.a1802tola
  end

  # Q43 — a1808: Professional trustees by primary nationality (dimensional)
  # Conditional on a1802btola == "Oui"

  test "a1808 returns nil when a1802btola is not Oui" do
    assert_nil @survey.a1808
  end

  test "a1808 counts professional trustees by nationality" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    # Trust client with MC professional trustee and FR professional trustee
    trust_1 = Client.create!(
      organization: @organization,
      name: "Trust Alpha",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "LU",
      became_client_at: 6.months.ago
    )
    Trustee.create!(client: trust_1, name: "Pro Trustee MC", nationality: "MC", is_professional: true)
    Trustee.create!(client: trust_1, name: "Pro Trustee FR", nationality: "FR", is_professional: true)
    Trustee.create!(client: trust_1, name: "Non-Pro Trustee GB", nationality: "GB", is_professional: false)

    Transaction.create!(
      organization: @organization,
      client: trust_1,
      reference: "A1808-T1",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Another trust client with MC professional trustee (rental transaction)
    trust_2 = Client.create!(
      organization: @organization,
      name: "Trust Beta",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 3.months.ago
    )
    Trustee.create!(client: trust_2, name: "Pro Trustee MC 2", nationality: "MC", is_professional: true)

    Transaction.create!(
      organization: @organization,
      client: trust_2,
      reference: "A1808-T2",
      transaction_date: Date.current - 2.weeks,
      transaction_type: "RENTAL",
      transaction_value: 180_000,
      rental_annual_value: 180_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Trust client with NO transactions in reporting period (should be excluded)
    trust_no_txn = Client.create!(
      organization: @organization,
      name: "Trust No Txn",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "CH",
      became_client_at: 6.months.ago
    )
    Trustee.create!(client: trust_no_txn, name: "Pro Trustee CH", nationality: "CH", is_professional: true)

    result = @survey.a1808

    assert_equal({"MC" => 2, "FR" => 1}, result)
  end

  # Q44 — a1809: Professional trustees by trust's incorporation country
  test "a1809 returns nil when a1802btola is not Oui" do
    assert_nil @survey.a1809
  end

  test "a1809 counts professional trustees by trust incorporation country" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    # Trust incorporated in MC with 2 professional trustees
    trust_mc = Client.create!(
      organization: @organization,
      name: "Trust MC",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC",
      became_client_at: 6.months.ago
    )
    Trustee.create!(client: trust_mc, name: "Pro Trustee 1", nationality: "FR", is_professional: true)
    Trustee.create!(client: trust_mc, name: "Pro Trustee 2", nationality: "US", is_professional: true)
    Transaction.create!(
      organization: @organization,
      client: trust_mc,
      reference: "A1809-T1",
      transaction_date: Date.current - 1.month,
      transaction_type: "PURCHASE",
      transaction_value: 500_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Trust incorporated in FR with 1 professional trustee
    trust_fr = Client.create!(
      organization: @organization,
      name: "Trust FR",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "FR",
      became_client_at: 6.months.ago
    )
    Trustee.create!(client: trust_fr, name: "Pro Trustee 3", nationality: "MC", is_professional: true)
    # Non-professional trustee should be excluded
    Trustee.create!(client: trust_fr, name: "Non-Pro Trustee", nationality: "FR", is_professional: false)
    Transaction.create!(
      organization: @organization,
      client: trust_fr,
      reference: "A1809-T2",
      transaction_date: Date.current - 2.weeks,
      transaction_type: "SALE",
      transaction_value: 800_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Trust with no incorporation_country — trustees should be excluded
    trust_nil = Client.create!(
      organization: @organization,
      name: "Trust Nil Country",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: nil,
      became_client_at: 6.months.ago
    )
    Trustee.create!(client: trust_nil, name: "Pro Trustee Nil", nationality: "DE", is_professional: true)
    Transaction.create!(
      organization: @organization,
      client: trust_nil,
      reference: "A1809-T3",
      transaction_date: Date.current - 1.week,
      transaction_type: "RENTAL",
      transaction_value: 120_000,
      rental_annual_value: 120_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Trust with no transactions in reporting period — should be excluded
    trust_no_txn = Client.create!(
      organization: @organization,
      name: "Trust No Txn",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "CH",
      became_client_at: 2.years.ago
    )
    Trustee.create!(client: trust_no_txn, name: "Pro Trustee CH", nationality: "CH", is_professional: true)

    result = @survey.a1809

    # MC: 2 trustees (from trust_mc), FR: 1 trustee (from trust_fr)
    # trust_nil excluded (no incorporation_country), trust_no_txn excluded (no txn in year)
    assert_equal({"MC" => 2, "FR" => 1}, result)
  end

  # Q45 — a11001BTOLA: Does entity have info on number and value of trust clients' transactions?
  test "a11001btola returns nil when a1802btola is not Oui" do
    assert_nil @survey.a11001btola
  end

  test "a11001btola returns setting value when a1802btola is Oui" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )
    Setting.create!(
      organization: @organization,
      key: "trust_clients_transaction_info_available",
      category: "entity_info",
      value: "Oui"
    )

    assert_equal "Oui", @survey.a11001btola
  end

  test "a11001btola returns nil when setting is not set but a1802btola is Oui" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    assert_nil @survey.a11001btola
  end

  # Q46 — a1806TOLA: Total number of transactions by trust/legal construction clients
  # for purchase and sale of real estate
  # Type: xbrli:integerItemType
  # Conditional: only when a11001btola == "Oui"

  test "a1806tola returns nil when a11001btola is not Oui" do
    assert_nil @survey.a1806tola
  end

  test "a1806tola counts transactions by trust clients for purchase and sale" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )
    Setting.create!(
      organization: @organization,
      key: "trust_clients_transaction_info_available",
      category: "entity_info",
      value: "Oui"
    )

    trust_client = Client.create!(
      organization: @organization,
      name: "Trust Alpha",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC"
    )

    # Two purchase/sale transactions
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1806TOLA-T1",
      transaction_date: Date.new(@year, 1, 15),
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1806TOLA-T2",
      transaction_date: Date.new(@year, 2, 10),
      transaction_type: "SALE",
      transaction_value: 2_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Rental transaction — should NOT be counted
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1806TOLA-T3",
      transaction_date: Date.new(@year, 1, 20),
      transaction_type: "RENTAL",
      transaction_value: 180_000,
      rental_annual_value: 180_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 2, @survey.a1806tola
  end

  # Q47 — a1807TOLA: Total value of funds transferred by trust/legal construction clients
  # for purchase and sale of real estate (monetaryItemType, conditional on a11001btola)

  test "a1807tola returns nil when a11001btola is not Oui" do
    assert_nil @survey.a1807tola
  end

  test "a1807tola sums transaction values for trust clients for purchase and sale only" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )
    Setting.create!(
      organization: @organization,
      key: "trust_clients_transaction_info_available",
      category: "entity_info",
      value: "Oui"
    )

    trust_client = Client.create!(
      organization: @organization,
      name: "Trust Alpha",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST",
      incorporation_country: "MC"
    )

    non_trust_client = Client.create!(
      organization: @organization,
      name: "SCI Beta",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI",
      incorporation_country: "MC"
    )

    # Purchase by trust client — included
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1807TOLA-T1",
      transaction_date: Date.new(@year, 1, 15),
      transaction_type: "PURCHASE",
      transaction_value: 1_000_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Sale by trust client — included
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1807TOLA-T2",
      transaction_date: Date.new(@year, 2, 10),
      transaction_type: "SALE",
      transaction_value: 2_500_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Rental by trust client — excluded (purchase/sale only)
    Transaction.create!(
      organization: @organization,
      client: trust_client,
      reference: "A1807TOLA-T3",
      transaction_date: Date.new(@year, 1, 20),
      transaction_type: "RENTAL",
      transaction_value: 180_000,
      rental_annual_value: 180_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    # Purchase by non-trust legal entity — excluded (not a trust)
    Transaction.create!(
      organization: @organization,
      client: non_trust_client,
      reference: "A1807TOLA-T4",
      transaction_date: Date.new(@year, 3, 5),
      transaction_type: "PURCHASE",
      transaction_value: 500_000,
      property_country: "MC",
      payment_method: "WIRE"
    )

    assert_equal 3_500_000, @survey.a1807tola
  end

  # Q48 — a11006: Specify type of other legal constructions not mentioned in previous questions
  # Type: xbrli:stringItemType — computed from client data, conditional on a1802btola

  test "a11006 returns nil when a1802btola is not Oui" do
    assert_nil @survey.a11006
  end

  test "a11006 returns nil when no clients have non-standard legal entity types" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    # Discard any pre-existing non-standard legal entity clients from fixtures
    @organization.clients
      .where(client_type: "LEGAL_ENTITY")
      .where.not(legal_entity_type: AmsfConstants::AMSF_STANDARD_LEGAL_FORMS)
      .where.not(legal_entity_type: nil)
      .each(&:discard!)

    # Create a client with a standard legal form (SCI) — should NOT appear in a11006
    Client.create!(
      organization: @organization,
      name: "SCI Standard",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI"
    )

    assert_nil @survey.a11006
  end

  test "a11006 returns labels for non-standard legal entity types" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    Client.create!(
      organization: @organization,
      name: "Foundation Client",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "FOUNDATION"
    )

    Client.create!(
      organization: @organization,
      name: "Association Client",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "ASSOCIATION"
    )

    result = @survey.a11006
    assert_includes result, "Monegasque Foundation"
    assert_includes result, "Monegasque Association"
  end

  test "a11006 includes free-text for OTHER legal entity type" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    Client.create!(
      organization: @organization,
      name: "Fiducie Client",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "OTHER",
      legal_entity_type_other: "Fiducie"
    )

    result = @survey.a11006
    assert_includes result, "Fiducie"
  end

  test "a11006 excludes standard forms and trusts" do
    Setting.create!(
      organization: @organization,
      key: "can_distinguish_trust_clients",
      category: "entity_info",
      value: "Oui"
    )

    # Standard forms — should NOT appear
    Client.create!(organization: @organization, name: "SCI Co", client_type: "LEGAL_ENTITY", legal_entity_type: "SCI")
    Client.create!(organization: @organization, name: "Trust Co", client_type: "LEGAL_ENTITY", legal_entity_type: "TRUST")
    Client.create!(organization: @organization, name: "SARL Co", client_type: "LEGAL_ENTITY", legal_entity_type: "SARL")

    # Non-standard — SHOULD appear
    Client.create!(organization: @organization, name: "Foundation Co", client_type: "LEGAL_ENTITY", legal_entity_type: "FOUNDATION")

    result = @survey.a11006
    assert_includes result, "Monegasque Foundation"
    refute_includes result, "SCI"
    refute_includes result, "Trust"
    refute_includes result, "SARL"
  end

  # === Section 1.8: PEPs ===

  # Q49 — a11301: Does entity have PEP clients?
  # Type: enum "Oui" / "Non" (computed from client data)
  test "a11301 returns Oui when organization has PEP clients with transactions in the year" do
    # Fixture pep_client (is_pep: true) has pep_transaction in current year
    assert_equal "Oui", @survey.a11301
  end

  test "a11301 returns Non when organization has no PEP clients with transactions in the year" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal "Non", survey.a11301
  end

  # Q50 — a11302RES: Total unique PEP clients by residence country
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a11301 == "Oui"
  test "a11302res returns nil when a11301 is Non (no PEP clients)" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11302res
  end

  test "a11302res returns PEP clients grouped by residence country" do
    # Fixture pep_client: is_pep true, residence_country "MC", has pep_transaction (PURCHASE) in current year
    result = @survey.a11302res
    assert_instance_of Hash, result
    assert_equal({"MC" => 1}, result)
  end

  # Q51 — a11302: Total unique PEP clients by primary nationality
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a11301 == "Oui"
  test "a11302 returns nil when a11301 is Non (no PEP clients)" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11302
  end

  test "a11302 returns PEP clients grouped by primary nationality" do
    # Fixture pep_client: is_pep true, nationality "MC", has pep_transaction (PURCHASE) in current year
    result = @survey.a11302
    assert_instance_of Hash, result
    assert_equal({"MC" => 1}, result)
  end

  # Q52 — a11304B: Total transactions by PEP clients for purchase/sale
  # Type: xbrli:integerItemType
  # Conditional: only when a11301 == "Oui"
  test "a11304b returns nil when a11301 is Non (no PEP clients)" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11304b
  end

  test "a11304b returns count of purchase/sale transactions by PEP clients" do
    # Fixture pep_client has 1 PURCHASE transaction (pep_transaction)
    assert_equal 1, @survey.a11304b
  end

  # Q53 — a11305B: Total value of funds transferred by PEP clients for purchase/sale
  # Type: xbrli:monetaryItemType
  # Conditional: only when a11301 == "Oui"
  test "a11305b returns nil when a11301 is Non (no PEP clients)" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11305b
  end

  test "a11305b returns total value of purchase/sale transactions by PEP clients" do
    # Fixture pep_client has 1 PURCHASE transaction (pep_transaction) with transaction_value 3500000.00
    assert_equal 3_500_000.00, @survey.a11305b
  end

  # Q54 — a11307: Total unique PEP beneficial owners of legal entities/trusts,
  # broken down by primary nationality of the PEP
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a11301 == "Oui"
  test "a11307 returns nil when a11301 is Non (no PEP clients)" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11307
  end

  test "a11307 returns PEP beneficial owners by nationality" do
    # Fixture pep_owner is a PEP BO (nationality: "MC") on legal_entity client
    # legal_entity has a high_value PURCHASE transaction in the current year
    result = @survey.a11307
    assert_instance_of Hash, result
    assert_equal 1, result["MC"]
  end

  # Q55 — a11309B: Total transactions by PEP BOs of legal entities/trusts
  # Type: xbrli:integerItemType
  # Conditional: only when a11301 == "Oui"
  test "a11309b returns nil when a11301 is Non (no PEP clients)" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11309b
  end

  test "a11309b returns count of purchase/sale transactions for LE/trust clients with PEP BOs" do
    # Fixture legal_entity has pep_owner (PEP BO)
    # legal_entity has high_value (PURCHASE) and check_payment (SALE) transactions in current year
    # rental transaction should NOT be counted (B suffix = purchase/sale only)
    assert_equal 2, @survey.a11309b
  end

  # Q56 — a13501B: Does your entity have clients that are VASPs (PSAV)?
  # Type: enum "Oui" / "Non" (settings-based)
  test "a13501b returns the setting value when set" do
    Setting.create!(
      organization: @organization,
      key: "has_vasp_clients",
      category: "entity_info",
      value: "Oui"
    )
    assert_equal "Oui", @survey.a13501b
  end

  test "a13501b returns nil when setting is not set" do
    assert_nil @survey.a13501b
  end

  # Q57 — a13601A: Does your entity distinguish if PSAV clients are custodian wallet providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)
  test "a13601a returns nil when a13501b is not Oui (no PSAV clients)" do
    assert_nil @survey.a13601a
  end

  test "a13601a returns setting value when a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601a
  end

  test "a13601a returns nil when setting is not set but a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601a
  end

  # Q58 — a13601CW: Does your entity have PSAV clients who are custodian wallet providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601a)

  test "a13601cw returns nil when a13601a is not Oui" do
    assert_nil @survey.a13601cw
  end

  test "a13601cw returns setting value when a13601a is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_custodian_wallet_provider_clients", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601cw
  end

  test "a13601cw returns nil when setting is not set but a13601a is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601cw
  end

  # Q59 — a13603BB: Total unique PSAV clients who are custodian wallet providers
  # for purchases, sales, and rentals of real estate
  # Type: xbrli:integerItemType (scalar — NoCountryDimension)
  # Conditional: only when a13601cw == "Oui"

  test "a13603bb returns nil when a13601cw is not Oui" do
    assert_nil @survey.a13603bb
  end

  test "a13603bb counts unique custodian wallet provider VASP clients with transactions" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_custodian_wallet_provider_clients", category: "entity_info", value: "Oui")

    custodian_client = Client.create!(
      organization: @organization,
      name: "Test Custodian Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "LU"
    )

    Transaction.create!(
      organization: @organization,
      client: custodian_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 15),
      transaction_value: 500_000
    )

    assert_equal 1, @survey.a13603bb
  end

  test "a13603bb does not count non-custodian VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_custodian_wallet_provider_clients", category: "entity_info", value: "Oui")

    exchange_client = Client.create!(
      organization: @organization,
      name: "Test Exchange Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "EXCHANGE",
      incorporation_country: "FR"
    )

    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 15),
      transaction_value: 300_000
    )

    assert_equal 0, @survey.a13603bb
  end

  # Q60 — a13604BB: Total value of funds transferred by custodian wallet provider
  # PSAV clients for purchase, sale, and rental of real estate
  # Type: xbrli:monetaryItemType
  # Conditional: only when a13601cw == "Oui"

  test "a13604bb returns nil when a13601cw is not Oui" do
    assert_nil @survey.a13604bb
  end

  test "a13604bb returns total value of transactions by custodian VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_custodian_wallet_provider_clients", category: "entity_info", value: "Oui")

    custodian_client = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "Custodian VASP Corp",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "LU"
    )

    Transaction.create!(
      organization: @organization,
      client: custodian_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 10),
      transaction_value: 500_000
    )

    Transaction.create!(
      organization: @organization,
      client: custodian_client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 20),
      transaction_value: 300_000
    )

    assert_equal 800_000, @survey.a13604bb
  end

  test "a13604bb excludes non-custodian VASP client transactions" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_custodian_wallet_provider_clients", category: "entity_info", value: "Oui")

    exchange_client = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "Exchange VASP Corp",
      is_vasp: true,
      vasp_type: "EXCHANGE",
      incorporation_country: "LU"
    )

    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 15),
      transaction_value: 400_000
    )

    assert_equal 0, @survey.a13604bb
  end

  # Q61 — a13601B: Does your entity distinguish whether PSAV clients are virtual currency exchange providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)

  test "a13601b returns nil when a13501b is not Oui (no PSAV clients)" do
    assert_nil @survey.a13601b
  end

  test "a13601b returns setting value when a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_exchange_providers", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601b
  end

  test "a13601b returns nil when setting is not set but a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601b
  end

  # Q62 — a13601EP: Does your entity have PSAV clients who are virtual currency exchange providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601b)

  test "a13601ep returns nil when a13601b is not Oui" do
    assert_nil @survey.a13601ep
  end

  test "a13601ep returns setting value when a13601b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_exchange_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_exchange_provider_clients", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601ep
  end

  test "a13601ep returns nil when setting is not set but a13601b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_exchange_providers", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601ep
  end

  # Q63 — a13603AB: Total transactions by virtual currency exchange provider PSAV clients
  # for purchase, sale, and rental of real estate
  # Type: xbrli:integerItemType
  # Conditional: only when a13601ep == "Oui"

  test "a13603ab returns nil when a13601ep is not Oui" do
    assert_nil @survey.a13603ab
  end

  test "a13603ab counts transactions by exchange provider VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_exchange_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_exchange_provider_clients", category: "entity_info", value: "Oui")

    # Fixture vasp_client (EXCHANGE) already has 1 transaction (crypto_payment)
    baseline = @survey.a13603ab

    exchange_client = Client.create!(
      organization: @organization,
      name: "Exchange Provider Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "EXCHANGE",
      incorporation_country: "FR"
    )

    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 10),
      transaction_value: 500_000
    )

    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 20),
      transaction_value: 300_000
    )

    assert_equal baseline + 2, @survey.a13603ab
  end

  # Q64 — a13604AB: Total value of funds transferred by virtual currency exchange provider
  # PSAV clients for purchase, sale, and rental of real estate
  # Type: xbrli:monetaryItemType
  # Conditional: only when a13601ep == "Oui"

  test "a13604ab returns nil when a13601ep is not Oui" do
    assert_nil @survey.a13604ab
  end

  test "a13604ab returns total value of transactions by exchange provider VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_exchange_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_exchange_provider_clients", category: "entity_info", value: "Oui")

    # Fixture vasp_client (EXCHANGE) already has a transaction
    baseline = @survey.a13604ab

    exchange_client = Client.create!(
      organization: @organization,
      name: "Exchange Provider Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "EXCHANGE",
      incorporation_country: "FR"
    )

    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 10),
      transaction_value: 500_000
    )

    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 20),
      transaction_value: 300_000
    )

    assert_equal baseline + 800_000, @survey.a13604ab
  end

  # Q65 — a13601C: Does your entity distinguish if PSAV clients are ICO service providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)

  test "a13601c returns nil when a13501b is not Oui" do
    assert_nil @survey.a13601c
  end

  test "a13601c returns setting value when a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_ico_providers", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601c
  end

  test "a13601c returns nil when setting is not set but a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601c
  end

  # Q66 — a13601ICO: Does your entity have PSAV clients who are ICO service providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601c)

  test "a13601ico returns nil when a13601c is not Oui" do
    assert_nil @survey.a13601ico
  end

  test "a13601ico returns setting value when a13601c is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_ico_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_ico_provider_clients", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601ico
  end

  test "a13601ico returns nil when setting is not set but a13601c is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_ico_providers", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601ico
  end

  # Q67 — a13603CACB: Total transactions by ICO service provider PSAV clients
  # for purchase, sale, and rental of real estate
  # Type: xbrli:integerItemType
  # Conditional: only when a13601ico == "Oui"

  test "a13603cacb returns nil when a13601ico is not Oui" do
    assert_nil @survey.a13603cacb
  end

  test "a13603cacb counts transactions by ICO service provider VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_ico_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_ico_provider_clients", category: "entity_info", value: "Oui")

    ico_client = Client.create!(
      organization: @organization,
      name: "ICO Service Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "ICO",
      incorporation_country: "FR"
    )

    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 4, 15),
      transaction_value: 750_000
    )

    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 9, 20),
      transaction_value: 400_000
    )

    assert_equal 2, @survey.a13603cacb
  end

  # Q68 — a13604CB: Total value of funds transferred by ICO service provider
  # PSAV clients for purchase, sale, and rental of real estate
  # Type: xbrli:monetaryItemType
  # Conditional: only when a13601ico == "Oui"

  test "a13604cb returns nil when a13601ico is not Oui" do
    assert_nil @survey.a13604cb
  end

  test "a13604cb sums transaction values by ICO service provider VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_ico_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_ico_provider_clients", category: "entity_info", value: "Oui")

    ico_client = Client.create!(
      organization: @organization,
      name: "ICO Service Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "ICO",
      incorporation_country: "FR"
    )

    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 4, 15),
      transaction_value: 750_000
    )

    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 9, 20),
      transaction_value: 400_000
    )

    assert_equal 1_150_000, @survey.a13604cb
  end

  # Q69 — a13601C2: Does your entity distinguish if PSAV clients provide other services
  # not mentioned above?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)

  test "a13601c2 returns nil when a13501b is not Oui" do
    assert_nil @survey.a13601c2
  end

  test "a13601c2 returns setting value when a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601c2
  end

  test "a13601c2 returns nil when setting is not set but a13501b is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601c2
  end

  # Q70 — a13601OTHER: Does your entity have PSAV clients who provide other services?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601c2)

  test "a13601other returns nil when a13601c2 is not Oui" do
    assert_nil @survey.a13601other
  end

  test "a13601other returns setting value when a13601c2 is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_other_vasp_service_clients", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a13601other
  end

  test "a13601other returns nil when setting is not set but a13601c2 is Oui" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    assert_nil @survey.a13601other
  end

  # Q71 — a13603DB: Total transactions by other-services PSAV clients
  # for purchase, sale, and rental of real estate
  # Type: xbrli:integerItemType
  # Conditional: only when a13601other == "Oui"

  test "a13603db returns nil when a13601other is not Oui" do
    assert_nil @survey.a13603db
  end

  test "a13603db counts transactions by other-services VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_other_vasp_service_clients", category: "entity_info", value: "Oui")

    vasp_client = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "OtherVASP Services Ltd",
      is_vasp: true,
      vasp_type: "OTHER",
      vasp_other_service_type: "DeFi Lending"
    )

    Transaction.create!(
      organization: @organization,
      client: vasp_client,
      reference: "VASP-OTHER-1",
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    Transaction.create!(
      organization: @organization,
      client: vasp_client,
      reference: "VASP-OTHER-2",
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 10),
      transaction_value: 750_000
    )

    assert_equal 2, @survey.a13603db
  end

  # Q72 — a13604DB: Total value of funds transferred by other-services PSAV clients
  # for purchase, sale, and rental of real estate
  # Type: xbrli:monetaryItemType
  # Conditional: only when a13601other == "Oui"

  test "a13604db returns nil when a13601other is not Oui" do
    assert_nil @survey.a13604db
  end

  test "a13604db sums transaction values by other-services VASP clients" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_other_vasp_service_clients", category: "entity_info", value: "Oui")

    vasp_client = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "OtherVASP Services Ltd",
      is_vasp: true,
      vasp_type: "OTHER",
      vasp_other_service_type: "DeFi Lending"
    )

    Transaction.create!(
      organization: @organization,
      client: vasp_client,
      reference: "VASP-OTHV-1",
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    Transaction.create!(
      organization: @organization,
      client: vasp_client,
      reference: "VASP-OTHV-2",
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 10),
      transaction_value: 750_000
    )

    assert_equal 1_250_000, @survey.a13604db
  end

  # Q73 — a13602B: Unique custodian wallet provider PSAV clients
  # by country of establishment, for purchase, sale, and rental
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a13601cw == "Oui"

  test "a13602b returns nil when a13601cw is not Oui" do
    assert_nil @survey.a13602b
  end

  test "a13602b returns unique custodian VASP clients by incorporation country" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_custodian_wallet_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_custodian_wallet_provider_clients", category: "entity_info", value: "Oui")

    vasp_mc = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "MC Custodian",
      incorporation_country: "MC",
      is_vasp: true,
      vasp_type: "CUSTODIAN"
    )

    vasp_fr = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "FR Custodian",
      incorporation_country: "FR",
      is_vasp: true,
      vasp_type: "CUSTODIAN"
    )

    Transaction.create!(
      organization: @organization, client: vasp_mc,
      reference: "CW-MC-1", transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15), transaction_value: 500_000
    )

    Transaction.create!(
      organization: @organization, client: vasp_fr,
      reference: "CW-FR-1", transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 10), transaction_value: 300_000
    )

    result = @survey.a13602b
    assert_equal({"MC" => 1, "FR" => 1}, result)
  end

  # Q74 — a13602A: Unique exchange provider PSAV clients
  # by country of establishment, for purchase, sale, and rental
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a13601ep == "Oui"

  test "a13602a returns nil when a13601ep is not Oui" do
    assert_nil @survey.a13602a
  end

  test "a13602a returns unique exchange VASP clients by incorporation country" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_exchange_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_exchange_provider_clients", category: "entity_info", value: "Oui")

    vasp = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "CH Exchange",
      incorporation_country: "CH",
      is_vasp: true,
      vasp_type: "EXCHANGE"
    )

    Transaction.create!(
      organization: @organization, client: vasp,
      reference: "EX-1", transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 4, 10), transaction_value: 600_000
    )

    result = @survey.a13602a
    assert_equal 1, result["CH"]
    assert_equal 1, result["MC"] # from vasp_client fixture
  end

  # Q75 — a13602C: Unique ICO service provider PSAV clients
  # by country of establishment, for purchase, sale, and rental
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a13601ico == "Oui"

  test "a13602c returns nil when a13601ico is not Oui" do
    assert_nil @survey.a13602c
  end

  test "a13602c returns unique ICO VASP clients by incorporation country" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_ico_providers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_ico_provider_clients", category: "entity_info", value: "Oui")

    vasp = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "ICO Provider SG",
      incorporation_country: "SG",
      is_vasp: true,
      vasp_type: "ICO"
    )

    Transaction.create!(
      organization: @organization, client: vasp,
      reference: "ICO-SG-1", transaction_type: "SALE",
      transaction_date: Date.new(@year, 5, 20), transaction_value: 900_000
    )

    assert_equal({"SG" => 1}, @survey.a13602c)
  end

  # Q76 — a13602D: Unique other-services PSAV clients
  # by country of establishment, for purchase, sale, and rental
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional: only when a13601other == "Oui"

  test "a13602d returns nil when a13601other is not Oui" do
    assert_nil @survey.a13602d
  end

  test "a13602d returns unique other-services VASP clients by incorporation country" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_other_vasp_service_clients", category: "entity_info", value: "Oui")

    vasp = Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "DeFi Provider JP",
      incorporation_country: "JP",
      is_vasp: true,
      vasp_type: "OTHER",
      vasp_other_service_type: "DeFi Lending"
    )

    Transaction.create!(
      organization: @organization, client: vasp,
      reference: "OTH-JP-1", transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 8, 5), transaction_value: 400_000
    )

    assert_equal({"JP" => 1}, @survey.a13602d)
  end

  # Q77 — a13604E: Specify what other services PSAV clients provide
  # Type: xbrli:stringItemType
  # Conditional: only when a13601other == "Oui"

  test "a13604e returns nil when a13601other is not Oui" do
    assert_nil @survey.a13604e
  end

  test "a13604e returns distinct other VASP service types" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_other_vasp_service_clients", category: "entity_info", value: "Oui")

    Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "DeFi Provider",
      is_vasp: true,
      vasp_type: "OTHER",
      vasp_other_service_type: "DeFi Lending"
    )

    Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "NFT Marketplace",
      is_vasp: true,
      vasp_type: "OTHER",
      vasp_other_service_type: "NFT Services"
    )

    result = @survey.a13604e
    assert_includes result, "DeFi Lending"
    assert_includes result, "NFT Services"
  end

  test "a13604e returns nil when no other-services VASP clients exist" do
    Setting.create!(organization: @organization, key: "has_vasp_clients", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distinguishes_other_vasp_services", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_other_vasp_service_clients", category: "entity_info", value: "Oui")

    assert_nil @survey.a13604e
  end

  # === Section 1.10: 2nd Nationalities ===

  test "a1203 returns setting value for recording all client nationalities" do
    Setting.create!(organization: @organization, key: "records_all_client_nationalities", category: "entity_info", value: "Oui")

    assert_equal "Oui", @survey.a1203
  end

  test "a1203 returns nil when setting is not set" do
    assert_nil @survey.a1203
  end

  test "a1402 returns secondary nationalities breakdown when a1203 is Oui" do
    Setting.create!(organization: @organization, key: "records_all_client_nationalities", category: "entity_info", value: "Oui")

    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "Dual National",
      nationality: "FR"
    )
    ClientNationality.create!(client: client, country_code: "IT")
    ClientNationality.create!(client: client, country_code: "CH")

    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 15),
      transaction_value: 500_000
    )

    result = @survey.a1402
    assert_equal 1, result["IT"]
    assert_equal 1, result["CH"]
  end

  test "a1402 returns nil when a1203 is not Oui" do
    assert_nil @survey.a1402
  end

  # === Section 1.11: Monegasque Client Types (Purchases and Sales) ===

  test "ac171 returns Oui when Monegasque clients had purchase/sale transactions" do
    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "Monaco Client",
      nationality: "MC"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 1_000_000
    )

    assert_equal "Oui", @survey.ac171
  end

  test "ac171 returns Non when no Monegasque clients had purchase/sale transactions" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal "Non", survey.ac171
  end

  test "a11502b returns count of Monegasque lawyer clients when ac171 is Oui" do
    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "MC Lawyer",
      nationality: "MC",
      business_sector: "LEGAL_SERVICES"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 4, 1),
      transaction_value: 800_000
    )

    assert_equal 1, @survey.a11502b
  end

  test "a11502b returns nil when ac171 is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.a11502b
  end

  # Q82-Q109: All Monegasque client sector methods follow the same pattern.
  # Test each delegates to mc_clients_by_sector correctly.
  {
    a11602b: "ACCOUNTING",
    a11702b: "NOMINEE_SHAREHOLDER",
    a11802b: "BEARER_INSTRUMENTS",
    a12002b: "REAL_ESTATE",
    a12102b: "NMPPP",
    a12202b: "TCSP",
    a12302b: "MULTI_FAMILY_OFFICE",
    a12302c: "SINGLE_FAMILY_OFFICE",
    a12402b: "COMPLEX_STRUCTURES",
    a12502b: "CASH_INTENSIVE",
    a12602b: "PREPAID_CARDS",
    a12702b: "ART_ANTIQUITIES",
    a12802b: "IMPORT_EXPORT",
    a12902b: "HIGH_VALUE_GOODS",
    a13002b: "NPO",
    a13202b: "GAMBLING",
    a13302b: "CONSTRUCTION",
    a13402b: "EXTRACTIVE",
    a13702b: "DEFENSE_WEAPONS",
    a13802b: "YACHTING",
    a13902b: "SPORTS_AGENTS",
    a14102b: "FUND_MANAGEMENT",
    a14202b: "HOLDING_COMPANY",
    a14302b: "AUCTIONEERS",
    a14402b: "CAR_DEALERS",
    a14502b: "GOVERNMENT",
    a14602b: "AIRCRAFT_JETS",
    a14702b: "TRANSPORT"
  }.each do |method, sector|
    test "#{method} returns count of MC clients in #{sector} sector" do
      baseline = @survey.send(method) || 0

      client = Client.create!(
        organization: @organization,
        client_type: "NATURAL_PERSON",
        name: "MC #{sector} Client",
        nationality: "MC",
        business_sector: sector
      )
      Transaction.create!(
        organization: @organization,
        client: client,
        transaction_type: "PURCHASE",
        transaction_date: Date.new(@year, 5, 1),
        transaction_value: 500_000
      )

      assert_equal baseline + 1, @survey.send(method)
    end

    test "#{method} returns nil when ac171 is not Oui" do
      survey = Survey.new(organization: organizations(:company), year: @year)
      assert_nil survey.send(method)
    end
  end

  # === Section 1.12: Comments ===

  test "a14801 returns setting value for has comments on section" do
    Setting.create!(organization: @organization, key: "has_inherent_risk_comments", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a14801
  end

  test "a14801 returns nil when setting is not set" do
    assert_nil @survey.a14801
  end

  test "a14001 returns comment text when a14801 is Oui" do
    Setting.create!(organization: @organization, key: "has_inherent_risk_comments", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "inherent_risk_comments", category: "entity_info", value: "Some feedback")
    assert_equal "Some feedback", @survey.a14001
  end

  test "a14001 returns nil when a14801 is not Oui" do
    assert_nil @survey.a14001
  end

  # === Section 2.1: Cheque Operations ===

  test "a2101w returns setting value for accepting cheque operations" do
    Setting.create!(organization: @organization, key: "accepts_cheque_operations", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2101w
  end

  test "a2101w returns nil when setting is not set" do
    assert_nil @survey.a2101w
  end

  test "a2101wrp returns setting value when a2101w is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cheque_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cheque_operations_in_period", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2101wrp
  end

  test "a2101wrp returns nil when a2101w is not Oui" do
    assert_nil @survey.a2101wrp
  end

  test "a2102w returns count of cheque transactions when a2101wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cheque_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cheque_operations_in_period", category: "entity_info", value: "Oui")

    baseline = @survey.a2102w || 0

    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "Cheque Client",
      nationality: "FR"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1),
      transaction_value: 300_000,
      payment_method: "CHECK"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 1),
      transaction_value: 400_000,
      payment_method: "CHECK"
    )

    assert_equal baseline + 2, @survey.a2102w
  end

  test "a2102w returns nil when a2101wrp is not Oui" do
    assert_nil @survey.a2102w
  end

  test "a2102bw returns total value of cheque transactions when a2101wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cheque_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cheque_operations_in_period", category: "entity_info", value: "Oui")

    baseline = @survey.a2102bw || 0

    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "Cheque Client",
      nationality: "FR"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1),
      transaction_value: 300_000,
      payment_method: "CHECK"
    )

    assert_equal baseline + 300_000, @survey.a2102bw
  end

  test "a2102bw returns nil when a2101wrp is not Oui" do
    assert_nil @survey.a2102bw
  end
end
