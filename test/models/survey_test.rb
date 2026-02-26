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
end
