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
  # Type: enum "Oui" / "Non" — always Oui since the CRM tracks BO nationality
  test "a1204s always returns Oui" do
    assert_equal "Oui", @survey.a1204s
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
  # Type: enum (Oui/Non) — always Oui since the CRM tracks BO ownership
  test "a1204o always returns Oui" do
    assert_equal "Oui", @survey.a1204o
  end

  # Q15 — a120425O: Total number of BOs holding at least 25%,
  # broken down by primary nationality (dimensional, integer counts)
  # Conditional on a1204o == "Oui" (always true since CRM tracks ownership)
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
  # Type: enum (Oui/Non) — always Oui since the CRM tracks BO residence
  test "a1203d always returns Oui" do
    assert_equal "Oui", @survey.a1203d
  end

  # Q17 — a1207O: Total number of BOs who are foreign residents (residence != MC),
  # holding 25% or more, broken down by primary nationality
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional on a1203d == "Oui" (always true since CRM tracks BO residence)
  test "a1207o returns count of foreign-resident BOs with 25%+ ownership grouped by nationality" do
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
    result = @survey.a1207o

    # owner_one (FR, MC residence, 51%), owner_two (MC, MC residence, 49%),
    # cascade_owner_one (MC, MC residence, 60%), etc. — all excluded
    # MC nationality BOs are all MC residents, so MC should not appear
    assert_nil result["MC"]
  end

  test "a1207o excludes BOs with less than 25% ownership" do
    result = @survey.a1207o

    # uhnwi_owner has CH nationality, MC residence, 20% — excluded (below 25%)
    assert_nil result["CH"]
  end

  test "a1207o excludes BOs with nil nationality" do
    result = @survey.a1207o

    assert_nil result[nil]
  end

  test "a1207o excludes BOs from other organizations" do
    result = @survey.a1207o

    # other_org_owner (FR, FR residence, 100%, org:two) should not appear
    # Total should be 3 (only org:one foreign-resident BOs with >= 25%)
    assert_equal 3, result.values.sum
  end

  test "a1207o returns empty hash when no foreign-resident BOs exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal({}, survey.a1207o)
  end

  # Q18 — a1210O: Total number of BOs who are non-residents (no residence recorded),
  # holding 25% or more, broken down by primary nationality
  # Type: xbrli:integerItemType — dimensional by country (hash of counts)
  # Conditional on a1203d == "Oui" (always true since CRM tracks BO residence)
  test "a1210o returns count of non-resident BOs with 25%+ ownership grouped by nationality" do
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
    result = @survey.a1210o

    # at_hnwi_threshold has FR residence, at_uhnwi_threshold has IT residence,
    # other_client_owner has IT residence — all have residence_country set, so excluded
    assert_nil result&.dig("FR")
    assert_nil result&.dig("IT")
  end

  test "a1210o excludes BOs with less than 25% ownership" do
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
    result = @survey.a1210o

    # minimal_owner has nil nationality and nil residence_country — excluded
    assert_nil result&.dig(nil)
  end

  # Q19 — a11201BCD: Does entity identify and record client type: HNWIs?
  # Type: enum "Oui" / "Non" — crm-capability-based
  test "a11201bcd always returns Oui since CRM identifies HNWIs" do
    assert_equal "Oui", @survey.a11201bcd
  end

  # Q20 — a11201BCDU: Does entity identify and record client type: UHNWIs?
  # Type: enum "Oui" / "Non" — crm-capability-based
  test "a11201bcdu always returns Oui since CRM identifies UHNWIs" do
    assert_equal "Oui", @survey.a11201bcdu
  end

  # Q21 — a1801: Does entity identify/record trusts and other legal constructions?
  # Type: enum "Oui" / "Non" — crm-capability-based
  test "a1801 always returns Oui since CRM identifies trusts" do
    assert_equal "Oui", @survey.a1801
  end

  # Q22 — a13601: Does entity have PSAV clients that provide other services?
  # Type: enum "Oui" / "Non" — computed from CRM VASP types
  test "a13601 returns Oui when organization has VASP clients with other service types" do
    Client.create!(
      organization: @organization,
      name: "VASP Transfer Client",
      client_type: "NATURAL_PERSON",
      nationality: "FR",
      residence_country: "FR",
      became_client_at: 3.months.ago,
      is_vasp: true,
      vasp_type: "OTHER",
      vasp_other_service_type: "Crypto ATM operator"
    )
    assert_equal "Oui", @survey.a13601
  end

  test "a13601 returns Non when no VASP clients with other service types exist" do
    assert_equal "Non", @survey.a13601
  end

  test "a13601 returns Non when VASP clients only have named types" do
    Client.create!(
      organization: @organization,
      name: "VASP Exchange Client",
      client_type: "NATURAL_PERSON",
      nationality: "FR",
      residence_country: "FR",
      became_client_at: 3.months.ago,
      is_vasp: true,
      vasp_type: "EXCHANGE"
    )
    assert_equal "Non", @survey.a13601
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

  test "air129 returns Oui when residence purchases exist" do
    # Fixtures for org :one already have 2 RESIDENCE purchases
    assert_equal "Oui", @survey.air129
  end

  test "air129 returns Non when no residence purchases exist" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_equal "Non", survey.air129
  end

  # Q32 — aIR1210: How many purchases have been made for the purpose of
  # establishing a residence in Monaco during the reporting period?
  # Type: xbrli:integerItemType (computed, conditional on air129)

  test "air1210 returns nil when air129 is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.air1210
  end

  test "air1210 counts purchase transactions with purchase_purpose RESIDENCE" do
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
  test "a155 returns Oui (CRM captures legal entity type and incorporation country)" do
    assert_equal "Oui", @survey.a155
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

  test "amles returns hash of Monegasque legal entity clients grouped by legal_entity_type" do
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

  test "a11206b returns hash of HNWI BOs grouped by nationality" do
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
      net_worth_range: "5M_TO_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    # Create another HNWI BO with different nationality
    BeneficialOwner.create!(
      client: le_client,
      name: "Rich Owner BE",
      nationality: "BE",
      net_worth_range: "5M_TO_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    # Create a non-HNWI BO (should not appear)
    BeneficialOwner.create!(
      client: le_client,
      name: "Normal Owner ES",
      nationality: "ES",
      net_worth_range: "UNDER_5M",
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
      net_worth_range: "5M_TO_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b
    assert_nil result["JP"]
  end

  test "a11206b excludes BOs of clients with only rental transactions" do
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
      net_worth_range: "5M_TO_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b
    assert_nil result["SE"]
  end

  test "a11206b does not double-count a BO even with multiple transactions on the client" do
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
      net_worth_range: "5M_TO_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a11206b
    assert_equal 1, result["NL"]
  end

  # Q39 — a112012B: UHNWI beneficial owners of legal entity clients by nationality

  test "a112012b returns hash of UHNWI BOs grouped by nationality" do
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
      net_worth_range: "OVER_50M",
      control_type: "DIRECT",
      is_pep: false
    )
    # UHNWI BO (>50M) — different nationality
    BeneficialOwner.create!(
      client: le_client,
      name: "UHNWI GB",
      nationality: "GB",
      net_worth_range: "OVER_50M",
      control_type: "DIRECT",
      is_pep: false
    )
    # HNWI but NOT UHNWI (>5M but <=50M) — should NOT be counted
    BeneficialOwner.create!(
      client: le_client,
      name: "HNWI Only DE",
      nationality: "DE",
      net_worth_range: "5M_TO_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a112012b
    assert_equal 1, result["FR"]
    assert_equal 1, result["GB"]
    assert_nil result["DE"]
  end

  test "a112012b excludes BOs of trust clients" do
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
      net_worth_range: "OVER_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a112012b
    assert_nil result["JP"]
  end

  test "a112012b excludes BOs of clients with only rental transactions" do
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
      net_worth_range: "OVER_50M",
      control_type: "DIRECT",
      is_pep: false
    )

    result = @survey.a112012b
    assert_nil result["KR"]
  end

  # Q40 — a1802BTOLA: Does entity distinguish if clients are trusts or other legal constructions?
  # Type: stringItemType with enum restriction ("Oui" / "Non") — crm-capability-based
  test "a1802btola returns Oui (CRM always captures legal_entity_type including TRUST)" do
    assert_equal "Oui", @survey.a1802btola
  end

  # Q41 — a1802TOLA: Total unique trust/legal construction clients
  # for purchases, sales, and rentals of real estate
  # Type: xbrli:integerItemType (scalar — NoCountryDimension)
  test "a1802tola counts unique trust clients for purchase/sale and rental" do
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
  test "a1807atola counts only Monegasque trust clients" do
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

  test "a1808 counts professional trustees by nationality" do
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
  test "a1809 counts professional trustees by trust incorporation country" do
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
  # Always "Oui" since CRM tracks trust client transactions
  test "a11001btola always returns Oui" do
    assert_equal "Oui", @survey.a11001btola
  end

  # Q46 — a1806TOLA: Total number of transactions by trust/legal construction clients
  # for purchase and sale of real estate
  # Type: xbrli:integerItemType

  test "a1806tola counts transactions by trust clients for purchase and sale" do
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
  # for purchase and sale of real estate (monetaryItemType)

  test "a1807tola sums transaction values for trust clients for purchase and sale only" do
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

  test "a11006 returns nil when no clients have non-standard legal entity types" do
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
  # Computed from clients table (is_vasp column)
  test "a13501b returns Oui when organization has VASP clients" do
    assert_equal "Oui", @survey.a13501b
  end

  test "a13501b returns Non when organization has no VASP clients" do
    @organization.clients.where(is_vasp: true).update_all(is_vasp: false)
    assert_equal "Non", @survey.a13501b
  end

  # Q57 — a13601A: Does your entity distinguish if PSAV clients are custodian wallet providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)
  # Q57 — a13601A: Does your entity distinguish if PSAV clients are custodian wallet providers?
  # Always "Oui" since CRM captures vasp_type on every VASP client
  test "a13601a always returns Oui" do
    assert_equal "Oui", @survey.a13601a
  end

  # Q58 — a13601CW: Does your entity have PSAV clients who are custodian wallet providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601a)

  # Q58 — a13601CW: Does your entity have PSAV clients who are custodian wallet providers?
  # Computed from clients table (is_vasp + vasp_type)
  test "a13601cw returns Oui when entity has custodian wallet provider clients" do
    Client.create!(
      organization: @organization,
      name: "Custodian Wallet Co",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "CUSTODIAN"
    )
    assert_equal "Oui", @survey.a13601cw
  end

  test "a13601cw returns Non when entity has no custodian wallet provider clients" do
    assert_equal "Non", @survey.a13601cw
  end

  # Q59 — a13603BB: Total unique PSAV clients who are custodian wallet providers
  # for purchases, sales, and rentals of real estate
  # Type: xbrli:integerItemType (scalar — NoCountryDimension)
  # Conditional: only when a13601cw == "Oui"

  test "a13603bb returns nil when a13601cw is not Oui" do
    assert_nil @survey.a13603bb
  end

  test "a13603bb counts unique custodian wallet provider VASP clients with transactions" do
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
    # Create a custodian client so a13601cw == "Oui"
    Client.create!(
      organization: @organization,
      name: "Custodian Co",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "LU"
    )

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

  test "a13603bb excludes clients with only non-qualifying rental transactions" do
    # Client with qualifying purchase
    custodian_client_a = Client.create!(
      organization: @organization,
      name: "Custodian A",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "LU"
    )

    Transaction.create!(
      organization: @organization,
      client: custodian_client_a,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    # Client with only non-qualifying rental (monthly < 10,000 EUR)
    custodian_client_b = Client.create!(
      organization: @organization,
      name: "Custodian B",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "DE"
    )

    Transaction.create!(
      organization: @organization,
      client: custodian_client_b,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )

    # Only client A should be counted
    assert_equal 1, @survey.a13603bb
  end

  # Q60 — a13604BB: Total value of funds transferred by custodian wallet provider
  # PSAV clients for purchase, sale, and rental of real estate
  # Type: xbrli:monetaryItemType
  # Conditional: only when a13601cw == "Oui"

  test "a13604bb returns nil when a13601cw is not Oui" do
    assert_nil @survey.a13604bb
  end

  test "a13604bb returns total value of transactions by custodian VASP clients" do
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
    # Create a custodian client so a13601cw == "Oui"
    Client.create!(
      organization: @organization,
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      name: "Custodian Co",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "LU"
    )

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

  test "a13604bb excludes rental transactions below 10000 EUR monthly rent" do
    custodian_client = Client.create!(
      organization: @organization,
      name: "Custodian Wallet Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "CUSTODIAN",
      incorporation_country: "LU"
    )

    # Qualifying rental
    Transaction.create!(
      organization: @organization,
      client: custodian_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 120_000,
      rental_annual_value: 120_000
    )

    # Non-qualifying rental
    Transaction.create!(
      organization: @organization,
      client: custodian_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 7, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )

    # Purchase
    Transaction.create!(
      organization: @organization,
      client: custodian_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    assert_equal 620_000, @survey.a13604bb
  end

  # Q61 — a13601B: Does your entity distinguish whether PSAV clients are virtual currency exchange providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)

  # Q61 — a13601B: Does your entity distinguish whether PSAV clients are exchange providers?
  # Always "Oui" since CRM captures vasp_type on every VASP client
  test "a13601b always returns Oui" do
    assert_equal "Oui", @survey.a13601b
  end

  # Q62 — a13601EP: Does your entity have PSAV clients who are virtual currency exchange providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601b)

  # Q62 — a13601EP: Does your entity have PSAV clients who are exchange providers?
  # Computed from clients table (is_vasp + vasp_type)
  test "a13601ep returns Oui when entity has exchange provider clients" do
    assert_equal "Oui", @survey.a13601ep
  end

  test "a13601ep returns Non when entity has no exchange provider clients" do
    @organization.clients.where(is_vasp: true, vasp_type: "EXCHANGE").update_all(vasp_type: "CUSTODIAN")
    assert_equal "Non", @survey.a13601ep
  end

  # Q63 — a13603AB: Total transactions by virtual currency exchange provider PSAV clients
  # for purchase, sale, and rental of real estate
  # Type: xbrli:integerItemType
  # Conditional: only when a13601ep == "Oui"

  test "a13603ab returns nil when a13601ep is not Oui" do
    @organization.clients.where(is_vasp: true, vasp_type: "EXCHANGE").update_all(vasp_type: "CUSTODIAN")
    assert_nil @survey.a13603ab
  end

  test "a13603ab counts transactions by exchange provider VASP clients" do
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

  test "a13603ab excludes rental transactions below 10000 EUR monthly rent" do
    baseline = @survey.a13603ab

    exchange_client = Client.create!(
      organization: @organization,
      name: "Exchange Provider Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "EXCHANGE",
      incorporation_country: "CH"
    )

    # Qualifying rental
    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 120_000,
      rental_annual_value: 120_000
    )

    # Non-qualifying rental
    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 7, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )

    # Purchase
    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    assert_equal baseline + 2, @survey.a13603ab
  end

  # Q64 — a13604AB: Total value of funds transferred by virtual currency exchange provider
  # PSAV clients for purchase, sale, and rental of real estate
  # Type: xbrli:monetaryItemType
  # Conditional: only when a13601ep == "Oui"

  test "a13604ab returns nil when a13601ep is not Oui" do
    @organization.clients.where(is_vasp: true, vasp_type: "EXCHANGE").update_all(vasp_type: "CUSTODIAN")
    assert_nil @survey.a13604ab
  end

  test "a13604ab returns total value of transactions by exchange provider VASP clients" do
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

  test "a13604ab excludes rental transactions below 10000 EUR monthly rent" do
    baseline = @survey.a13604ab

    exchange_client = Client.create!(
      organization: @organization,
      name: "Exchange Provider Corp",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "EXCHANGE",
      incorporation_country: "CH"
    )

    # Qualifying rental
    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 120_000,
      rental_annual_value: 120_000
    )

    # Non-qualifying rental
    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 7, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )

    # Purchase
    Transaction.create!(
      organization: @organization,
      client: exchange_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    assert_equal baseline + 620_000, @survey.a13604ab
  end

  # Q65 — a13601C: Does your entity distinguish if PSAV clients are ICO service providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13501b)

  # Q65 — a13601C: Does your entity distinguish if PSAV clients are ICO service providers?
  # Always "Oui" since CRM captures vasp_type on every VASP client
  test "a13601c always returns Oui" do
    assert_equal "Oui", @survey.a13601c
  end

  # Q66 — a13601ICO: Does your entity have PSAV clients who are ICO service providers?
  # Type: enum "Oui" / "Non" (settings-based, conditional on a13601c)

  # Q66 — a13601ICO: Does your entity have PSAV clients who are ICO service providers?
  # Computed from clients table (is_vasp + vasp_type)
  test "a13601ico returns Oui when entity has ICO provider clients" do
    Client.create!(
      organization: @organization,
      name: "ICO Provider Co",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "ICO"
    )
    assert_equal "Oui", @survey.a13601ico
  end

  test "a13601ico returns Non when entity has no ICO provider clients" do
    assert_equal "Non", @survey.a13601ico
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

  test "a13603cacb excludes rental transactions below 10000 EUR monthly rent" do
    ico_client = Client.create!(
      organization: @organization,
      name: "ICO Service Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "ICO",
      incorporation_country: "FR"
    )

    # Qualifying rental: annual value >= 120,000 (monthly >= 10,000)
    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 120_000,
      rental_annual_value: 120_000
    )

    # Non-qualifying rental: annual value < 120,000 (monthly < 10,000)
    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 7, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )

    # Purchase (always counts)
    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
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

  test "a13604cb excludes rental transactions below 10000 EUR monthly rent" do
    ico_client = Client.create!(
      organization: @organization,
      name: "ICO Service Provider",
      client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA",
      is_vasp: true,
      vasp_type: "ICO",
      incorporation_country: "FR"
    )

    # Qualifying rental: annual value >= 120,000
    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 6, 1),
      transaction_value: 120_000,
      rental_annual_value: 120_000
    )

    # Non-qualifying rental: annual value < 120,000
    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 7, 1),
      transaction_value: 60_000,
      rental_annual_value: 60_000
    )

    # Purchase (always counts)
    Transaction.create!(
      organization: @organization,
      client: ico_client,
      transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 15),
      transaction_value: 500_000
    )

    assert_equal 620_000, @survey.a13604cb
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
    @organization.clients.where(is_vasp: true, vasp_type: "EXCHANGE").update_all(vasp_type: "CUSTODIAN")
    assert_nil @survey.a13602a
  end

  test "a13602a returns unique exchange VASP clients by incorporation country" do
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

  test "a1203 always returns Oui" do
    assert_equal "Oui", @survey.a1203
  end

  test "a1402 returns secondary nationalities breakdown" do
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

  # === Section 2.2: Cheque Operations BY Clients ===

  test "a2101b returns setting value for clients performed cheque operations" do
    Setting.create!(organization: @organization, key: "clients_performed_cheque_operations", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2101b
  end

  test "a2101b returns nil when setting is not set" do
    assert_nil @survey.a2101b
  end

  test "a2102b returns count of cheque transactions by clients when a2101b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cheque_operations", category: "entity_info", value: "Oui")
    baseline = @survey.a2102b || 0

    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "Cheque Client By",
      nationality: "FR"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 5, 1),
      transaction_value: 600_000,
      payment_method: "CHECK"
    )

    assert_equal baseline + 1, @survey.a2102b
  end

  test "a2102b returns nil when a2101b is not Oui" do
    assert_nil @survey.a2102b
  end

  test "a2102bb returns total value of cheque transactions by clients when a2101b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cheque_operations", category: "entity_info", value: "Oui")
    baseline = @survey.a2102bb || 0

    client = Client.create!(
      organization: @organization,
      client_type: "NATURAL_PERSON",
      name: "Cheque Client By",
      nationality: "FR"
    )
    Transaction.create!(
      organization: @organization,
      client: client,
      transaction_type: "SALE",
      transaction_date: Date.new(@year, 5, 1),
      transaction_value: 600_000,
      payment_method: "CHECK"
    )

    assert_equal baseline + 600_000, @survey.a2102bb
  end

  test "a2102bb returns nil when a2101b is not Oui" do
    assert_nil @survey.a2102bb
  end

  # === Section 2.3: Wire Transfers WITH Clients ===

  test "a2104w returns setting value" do
    Setting.create!(organization: @organization, key: "accepts_wire_transfers", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2104w
  end

  test "a2104w returns nil when not set" do
    assert_nil @survey.a2104w
  end

  test "a2104wrp returns setting when a2104w is Oui" do
    Setting.create!(organization: @organization, key: "accepts_wire_transfers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_wire_transfers_in_period", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2104wrp
  end

  test "a2104wrp returns nil when a2104w is not Oui" do
    assert_nil @survey.a2104wrp
  end

  test "a2105w returns count of wire transfer transactions when a2104wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_wire_transfers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_wire_transfers_in_period", category: "entity_info", value: "Oui")
    baseline = @survey.a2105w || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Wire Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 4, 1), transaction_value: 750_000, payment_method: "WIRE")

    assert_equal baseline + 1, @survey.a2105w
  end

  test "a2105w returns nil when a2104wrp is not Oui" do
    assert_nil @survey.a2105w
  end

  test "a2105bw returns total value of wire transfers when a2104wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_wire_transfers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_wire_transfers_in_period", category: "entity_info", value: "Oui")
    baseline = @survey.a2105bw || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Wire Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 4, 1), transaction_value: 750_000, payment_method: "WIRE")

    assert_equal baseline + 750_000, @survey.a2105bw
  end

  test "a2105bw returns nil when a2104wrp is not Oui" do
    assert_nil @survey.a2105bw
  end

  # === Section 2.4: Wire Transfers BY Clients ===

  test "a2104b returns setting value" do
    Setting.create!(organization: @organization, key: "clients_performed_wire_transfers", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2104b
  end

  test "a2104b returns nil when not set" do
    assert_nil @survey.a2104b
  end

  test "a2105b returns count of wire transfer transactions by clients when a2104b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_wire_transfers", category: "entity_info", value: "Oui")
    baseline = @survey.a2105b || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Wire By Client", nationality: "DE")
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 900_000, payment_method: "WIRE")

    assert_equal baseline + 1, @survey.a2105b
  end

  test "a2105b returns nil when a2104b is not Oui" do
    assert_nil @survey.a2105b
  end

  test "a2105bb returns total value of wire transfers by clients when a2104b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_wire_transfers", category: "entity_info", value: "Oui")
    baseline = @survey.a2105bb || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Wire By Client", nationality: "DE")
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 900_000, payment_method: "WIRE")

    assert_equal baseline + 900_000, @survey.a2105bb
  end

  test "a2105bb returns nil when a2104b is not Oui" do
    assert_nil @survey.a2105bb
  end

  # === Section 2.5: Cash operations WITH clients ===

  # Q126 — a2107W: Does entity accept or carry out cash operations with clients?
  test "a2107w returns setting value for accepts_cash_operations" do
    assert_nil @survey.a2107w
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a2107w
  end

  # Q127 — a2107WRP: Did entity accept or carry out cash operations with clients during reporting period?
  test "a2107wrp returns setting value when a2107w is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2107wrp
  end

  test "a2107wrp returns nil when a2107w is not Oui" do
    assert_nil @survey.a2107wrp
  end

  # Q128 — a2108W: Total number of cash operations with clients
  test "a2108w returns count of cash operations when a2107wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    baseline = @survey.a2108w || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Cash Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH", cash_amount: 50_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "MIXED", cash_amount: 20_000)

    assert_equal baseline + 2, @survey.a2108w
  end

  test "a2108w returns nil when a2107wrp is not Oui" do
    assert_nil @survey.a2108w
  end

  # Q129 — a2109W: Total value of cash operations with clients
  test "a2109w returns total cash amount when a2107wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    baseline = @survey.a2109w || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Cash Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH", cash_amount: 50_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "MIXED", cash_amount: 20_000)

    assert_equal baseline + 70_000, @survey.a2109w
  end

  test "a2109w returns nil when a2107wrp is not Oui" do
    assert_nil @survey.a2109w
  end

  # Q130 — aG24010W: Total value of cash in foreign currencies with clients
  test "ag24010w returns total foreign currency cash amount when a2107wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    baseline = @survey.ag24010w || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "FX Cash Client", nationality: "US")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH",
      cash_amount: 50_000, foreign_currency_cash_amount: 30_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "MIXED",
      cash_amount: 20_000, foreign_currency_cash_amount: 15_000)

    assert_equal baseline + 45_000, @survey.ag24010w
  end

  test "ag24010w returns nil when a2107wrp is not Oui" do
    assert_nil @survey.ag24010w
  end

  # Q131 — a2110W: Cash operations >= 10,000 EUR with clients
  test "a2110w returns count of cash operations >= 10000 when a2107wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    baseline = @survey.a2110w || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Cash Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH", cash_amount: 10_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "CASH", cash_amount: 9_999)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 1), transaction_value: 200_000, payment_method: "MIXED", cash_amount: 15_000)

    assert_equal baseline + 2, @survey.a2110w
  end

  test "a2110w returns nil when a2107wrp is not Oui" do
    assert_nil @survey.a2110w
  end

  # Q132 — a2113W: Can entity distinguish cash ops > 100,000 EUR?
  test "a2113w returns setting value when a2107wrp is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_cash_over_100k", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2113w
  end

  test "a2113w returns nil when a2107wrp is not Oui" do
    assert_nil @survey.a2113w
  end

  # Q133 — a2113AW: Cash ops with natural persons > 100,000 EUR
  test "a2113aw returns count of NP cash ops > 100000 when a2113w is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_cash_over_100k", category: "entity_info", value: "Oui")
    baseline = @survey.a2113aw || 0

    np_client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "NP Cash", nationality: "FR")
    le_client = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "LE Cash",
      nationality: "FR", legal_entity_type: "SCI", incorporation_country: "MC")

    # NP cash > 100k — should count
    Transaction.create!(organization: @organization, client: np_client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)
    # NP cash <= 100k — should NOT count
    Transaction.create!(organization: @organization, client: np_client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "CASH", cash_amount: 100_000)
    # LE cash > 100k — should NOT count (wrong client type)
    Transaction.create!(organization: @organization, client: le_client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 7, 1), transaction_value: 300_000, payment_method: "CASH", cash_amount: 200_000)

    assert_equal baseline + 1, @survey.a2113aw
  end

  test "a2113aw returns nil when a2113w is not Oui" do
    assert_nil @survey.a2113aw
  end

  # Q134 — a2114A: Cash ops with Monegasque legal entities > 100,000 EUR
  test "a2114a returns count of MC LE cash ops > 100000 when a2113w is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_cash_over_100k", category: "entity_info", value: "Oui")
    baseline = @survey.a2114a || 0

    mc_le = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "MC LE",
      nationality: "MC", legal_entity_type: "SCI", incorporation_country: "MC")
    fr_le = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "FR LE",
      nationality: "FR", legal_entity_type: "SARL", incorporation_country: "FR")
    np = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "NP", nationality: "MC")

    # MC LE cash > 100k — should count
    Transaction.create!(organization: @organization, client: mc_le, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)
    # FR LE cash > 100k — should NOT count (foreign)
    Transaction.create!(organization: @organization, client: fr_le, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)
    # NP cash > 100k — should NOT count (not LE)
    Transaction.create!(organization: @organization, client: np, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 7, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)

    assert_equal baseline + 1, @survey.a2114a
  end

  test "a2114a returns nil when a2113w is not Oui" do
    assert_nil @survey.a2114a
  end

  # Q135 — a2115AW: Cash ops with foreign legal entities > 100,000 EUR
  test "a2115aw returns count of foreign LE cash ops > 100000 when a2113w is Oui" do
    Setting.create!(organization: @organization, key: "accepts_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "had_cash_operations_in_period", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_cash_over_100k", category: "entity_info", value: "Oui")
    baseline = @survey.a2115aw || 0

    mc_le = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "MC LE",
      nationality: "MC", legal_entity_type: "SCI", incorporation_country: "MC")
    fr_le = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "FR LE",
      nationality: "FR", legal_entity_type: "SARL", incorporation_country: "FR")

    # MC LE cash > 100k — should NOT count (Monegasque)
    Transaction.create!(organization: @organization, client: mc_le, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)
    # FR LE cash > 100k — should count (foreign)
    Transaction.create!(organization: @organization, client: fr_le, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)
    # FR LE cash <= 100k — should NOT count (too small)
    Transaction.create!(organization: @organization, client: fr_le, transaction_type: "SALE",
      transaction_date: Date.new(@year, 7, 1), transaction_value: 100_000, payment_method: "CASH", cash_amount: 100_000)

    assert_equal baseline + 1, @survey.a2115aw
  end

  test "a2115aw returns nil when a2113w is not Oui" do
    assert_nil @survey.a2115aw
  end

  # === Section 2.6: Cash operations BY clients ===

  # Q136 — a2107B: Did clients perform cash operations?
  test "a2107b returns setting value for clients_performed_cash_operations" do
    assert_nil @survey.a2107b
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a2107b
  end

  # Q137 — a2108B: Total cash operations count by clients
  test "a2108b returns count of cash operations when a2107b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    baseline = @survey.a2108b || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Cash By Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH", cash_amount: 50_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "MIXED", cash_amount: 20_000)

    assert_equal baseline + 2, @survey.a2108b
  end

  test "a2108b returns nil when a2107b is not Oui" do
    assert_nil @survey.a2108b
  end

  # Q138 — a2109B: Total value of cash operations by clients
  test "a2109b returns total cash amount when a2107b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    baseline = @survey.a2109b || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Cash By Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH", cash_amount: 50_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "MIXED", cash_amount: 20_000)

    assert_equal baseline + 70_000, @survey.a2109b
  end

  test "a2109b returns nil when a2107b is not Oui" do
    assert_nil @survey.a2109b
  end

  # Q139 — aG24010B: Total value of cash in foreign currencies by clients
  test "ag24010b returns total foreign currency cash amount when a2107b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    baseline = @survey.ag24010b || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "FX Cash By Client", nationality: "US")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH",
      cash_amount: 50_000, foreign_currency_cash_amount: 30_000)

    assert_equal baseline + 30_000, @survey.ag24010b
  end

  test "ag24010b returns nil when a2107b is not Oui" do
    assert_nil @survey.ag24010b
  end

  # Q140 — a2110B: Cash operations >= 10,000 EUR by clients
  test "a2110b returns count of cash operations >= 10000 when a2107b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    baseline = @survey.a2110b || 0

    client = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "Cash By Client", nationality: "FR")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 50_000, payment_method: "CASH", cash_amount: 10_000)
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 100_000, payment_method: "CASH", cash_amount: 9_999)

    assert_equal baseline + 1, @survey.a2110b
  end

  test "a2110b returns nil when a2107b is not Oui" do
    assert_nil @survey.a2110b
  end

  # Q141 — a2113B: Can entity distinguish cash ops > 100,000 EUR by clients?
  test "a2113b returns setting value when a2107b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_client_cash_over_100k", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a2113b
  end

  test "a2113b returns nil when a2107b is not Oui" do
    assert_nil @survey.a2113b
  end

  # Q142 — a2113AB: Cash ops by NP > 100,000 EUR
  test "a2113ab returns count of NP cash ops > 100000 when a2113b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_client_cash_over_100k", category: "entity_info", value: "Oui")
    baseline = @survey.a2113ab || 0

    np = Client.create!(organization: @organization, client_type: "NATURAL_PERSON", name: "NP Cash", nationality: "FR")
    Transaction.create!(organization: @organization, client: np, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)

    assert_equal baseline + 1, @survey.a2113ab
  end

  test "a2113ab returns nil when a2113b is not Oui" do
    assert_nil @survey.a2113ab
  end

  # Q143 — a2114AB: Cash ops by MC LE > 100,000 EUR
  test "a2114ab returns count of MC LE cash ops > 100000 when a2113b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_client_cash_over_100k", category: "entity_info", value: "Oui")
    baseline = @survey.a2114ab || 0

    mc_le = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "MC LE Cash",
      nationality: "MC", legal_entity_type: "SCI", incorporation_country: "MC")
    Transaction.create!(organization: @organization, client: mc_le, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)

    assert_equal baseline + 1, @survey.a2114ab
  end

  test "a2114ab returns nil when a2113b is not Oui" do
    assert_nil @survey.a2114ab
  end

  # Q144 — a2115AB: Cash ops by foreign LE > 100,000 EUR
  test "a2115ab returns count of foreign LE cash ops > 100000 when a2113b is Oui" do
    Setting.create!(organization: @organization, key: "clients_performed_cash_operations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_distinguish_client_cash_over_100k", category: "entity_info", value: "Oui")
    baseline = @survey.a2115ab || 0

    fr_le = Client.create!(organization: @organization, client_type: "LEGAL_ENTITY", name: "FR LE Cash",
      nationality: "FR", legal_entity_type: "SARL", incorporation_country: "FR")
    Transaction.create!(organization: @organization, client: fr_le, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 200_000, payment_method: "CASH", cash_amount: 150_000)

    assert_equal baseline + 1, @survey.a2115ab
  end

  test "a2115ab returns nil when a2113b is not Oui" do
    assert_nil @survey.a2115ab
  end

  # === Section 2.7: Virtual Currencies (Q145-Q148) ===

  # Q145 — a2201A: Does entity accept/conduct cryptocurrency operations with clients?
  test "a2201a returns setting value" do
    assert_nil @survey.a2201a

    Setting.create!(organization: @organization, key: "accepts_cryptocurrency_operations", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a2201a
  end

  # Q146 — a2201D: Plans to accept virtual currency payments next year?
  test "a2201d returns setting value" do
    assert_nil @survey.a2201d

    Setting.create!(organization: @organization, key: "plans_to_accept_virtual_currencies", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a2201d
  end

  # Q147 — a2202: Does entity have business relations with virtual asset platforms?
  test "a2202 returns setting value" do
    assert_nil @survey.a2202

    Setting.create!(organization: @organization, key: "has_virtual_asset_platform_relations", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a2202
  end

  # Q148 — a2203: Name the virtual asset platforms
  test "a2203 returns setting value when a2202 is Oui" do
    Setting.create!(organization: @organization, key: "has_virtual_asset_platform_relations", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "virtual_asset_platform_names", category: "entity_info", value: "Binance, Coinbase")
    assert_equal "Binance, Coinbase", @survey.a2203
  end

  test "a2203 returns nil when a2202 is not Oui" do
    assert_nil @survey.a2203
  end

  # === Section 2.8: Services Offered, Agent for Purchases & Sales (Q149-Q161) ===

  # Q149 — aIR233: Total unique clients by country for purchase/sale (dimensional)
  test "air233 returns unique client counts grouped by country" do
    baseline = @survey.air233

    np_fr = Client.create!(organization: @organization, name: "NP FR", client_type: "NATURAL_PERSON", nationality: "FR")
    np_fr2 = Client.create!(organization: @organization, name: "NP FR2", client_type: "NATURAL_PERSON", nationality: "FR")
    np_it = Client.create!(organization: @organization, name: "NP IT", client_type: "NATURAL_PERSON", nationality: "IT")
    le_ch = Client.create!(organization: @organization, name: "LE CH", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "CH")

    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "SALE",
      transaction_date: Date.new(@year, 2, 1), transaction_value: 200_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: np_fr2, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 150_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: np_it, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 4, 1), transaction_value: 300_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: le_ch, transaction_type: "SALE",
      transaction_date: Date.new(@year, 5, 1), transaction_value: 500_000, payment_method: "WIRE")

    result = @survey.air233
    assert_instance_of Hash, result
    assert_equal (baseline["FR"] || 0) + 2, result["FR"]  # 2 new unique FR clients
    assert_equal (baseline["IT"] || 0) + 1, result["IT"]  # 1 new unique IT client
    assert_equal (baseline["CH"] || 0) + 1, result["CH"]  # 1 new unique CH LE
  end

  # Q150 — aIR233B: How many unique clients were buyers?
  test "air233b returns count of unique buyer clients" do
    baseline = @survey.air233b || 0

    buyer = Client.create!(organization: @organization, name: "Buyer", client_type: "NATURAL_PERSON", nationality: "FR")
    seller = Client.create!(organization: @organization, name: "Seller", client_type: "NATURAL_PERSON", nationality: "IT")

    Transaction.create!(organization: @organization, client: buyer, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: buyer, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 2, 1), transaction_value: 200_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: seller, transaction_type: "SALE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 300_000, payment_method: "WIRE")

    assert_equal baseline + 1, @survey.air233b  # only 1 unique buyer (seller excluded)
  end

  # Q151 — aIR233S: How many unique clients were sellers?
  test "air233s returns count of unique seller clients" do
    baseline = @survey.air233s || 0

    buyer = Client.create!(organization: @organization, name: "Buyer", client_type: "NATURAL_PERSON", nationality: "FR")
    seller = Client.create!(organization: @organization, name: "Seller", client_type: "NATURAL_PERSON", nationality: "IT")

    Transaction.create!(organization: @organization, client: buyer, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: seller, transaction_type: "SALE",
      transaction_date: Date.new(@year, 2, 1), transaction_value: 200_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: seller, transaction_type: "SALE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 300_000, payment_method: "WIRE")

    assert_equal baseline + 1, @survey.air233s  # only 1 unique seller (buyer excluded)
  end

  # Q152 — aIR235B_1: Total transactions by country for purchase/sale (dimensional)
  test "air235b_1 returns transaction counts grouped by client country" do
    baseline = @survey.air235b_1

    np_fr = Client.create!(organization: @organization, name: "NP FR", client_type: "NATURAL_PERSON", nationality: "FR")
    le_ch = Client.create!(organization: @organization, name: "LE CH", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "CH")

    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "SALE",
      transaction_date: Date.new(@year, 2, 1), transaction_value: 200_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: le_ch, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 300_000, payment_method: "WIRE")

    result = @survey.air235b_1
    assert_instance_of Hash, result
    assert_equal (baseline["FR"] || 0) + 2, result["FR"]
    assert_equal (baseline["CH"] || 0) + 1, result["CH"]
  end

  # Q153 — aIR235B_2: For how many purchases/sales did you represent the buyer?
  test "air235b_2 returns count of transactions where agency represented buyer" do
    baseline = @survey.air235b_2 || 0

    client = Client.create!(organization: @organization, name: "Client", client_type: "NATURAL_PERSON", nationality: "FR")

    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE", agency_role: "BUYER_AGENT")
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 2, 1), transaction_value: 200_000, payment_method: "WIRE", agency_role: "SELLER_AGENT")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 300_000, payment_method: "WIRE", agency_role: "DUAL_AGENT")

    assert_equal baseline + 1, @survey.air235b_2  # only BUYER_AGENT counts
  end

  # Q154 — aIR235S: For how many purchases/sales did you represent the seller?
  test "air235s returns count of transactions where agency represented seller" do
    baseline = @survey.air235s || 0

    client = Client.create!(organization: @organization, name: "Client", client_type: "NATURAL_PERSON", nationality: "FR")

    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE", agency_role: "SELLER_AGENT")
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 2, 1), transaction_value: 200_000, payment_method: "WIRE", agency_role: "BUYER_AGENT")

    assert_equal baseline + 1, @survey.air235s
  end

  # Q155 — aIR237B: Total transactions by country for purchase/sale (5-year lookback, dimensional)
  test "air237b returns transaction counts by country over 5 years" do
    baseline = @survey.air237b

    np_fr = Client.create!(organization: @organization, name: "NP FR", client_type: "NATURAL_PERSON", nationality: "FR")

    # Current year transaction
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 100_000, payment_method: "WIRE")
    # 3 years ago transaction (within 5-year window)
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "SALE",
      transaction_date: Date.new(@year - 3, 6, 1), transaction_value: 200_000, payment_method: "WIRE")
    # 5 years ago transaction (outside 5-year window)
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year - 5, 1, 1), transaction_value: 300_000, payment_method: "WIRE")

    result = @survey.air237b
    assert_equal (baseline["FR"] || 0) + 2, result["FR"]  # 2 within 5-year window
  end

  # Q156 — aIR238B: Total value of funds transferred by client country for purchase/sale (dimensional, monetary)
  test "air238b returns total transaction values by country for current year" do
    baseline = @survey.air238b

    np_fr = Client.create!(organization: @organization, name: "NP FR", client_type: "NATURAL_PERSON", nationality: "FR")
    le_it = Client.create!(organization: @organization, name: "LE IT", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SCI", incorporation_country: "IT")

    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 500_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "SALE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 300_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: le_it, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 9, 1), transaction_value: 1_200_000, payment_method: "WIRE")

    result = @survey.air238b
    assert_equal (baseline["FR"] || 0) + 800_000, result["FR"]
    assert_equal (baseline["IT"] || 0) + 1_200_000, result["IT"]
  end

  # Q157 — aIR239B: Total value of funds transferred by client country, 5-year lookback (dimensional, monetary)
  test "air239b returns total transaction values by country over 5 years" do
    baseline = @survey.air239b

    np_fr = Client.create!(organization: @organization, name: "NP FR", client_type: "NATURAL_PERSON", nationality: "FR")

    # Current year transaction
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 1, 1), transaction_value: 500_000, payment_method: "WIRE")
    # 3 years ago transaction (within 5-year window)
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "SALE",
      transaction_date: Date.new(@year - 3, 6, 1), transaction_value: 300_000, payment_method: "WIRE")
    # 5 years ago transaction (outside 5-year window)
    Transaction.create!(organization: @organization, client: np_fr, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year - 5, 1, 1), transaction_value: 1_000_000, payment_method: "WIRE")

    result = @survey.air239b
    assert_equal (baseline["FR"] || 0) + 800_000, result["FR"]  # 500k + 300k within window
  end

  # Q158 — aIR117: How many purchases/sales were for investment purposes?
  test "air117 counts transactions with investment purchase purpose" do
    baseline = @survey.air117 || 0

    client = Client.create!(organization: @organization, name: "Investor", client_type: "NATURAL_PERSON", nationality: "FR")

    # Investment purchase — should count
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      purchase_purpose: "INVESTMENT", transaction_date: Date.new(@year, 3, 1), transaction_value: 500_000, payment_method: "WIRE")
    # Residence purchase — should not count
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      purchase_purpose: "RESIDENCE", transaction_date: Date.new(@year, 6, 1), transaction_value: 300_000, payment_method: "WIRE")
    # Sale (no purchase_purpose) — should not count
    Transaction.create!(organization: @organization, client: client, transaction_type: "SALE",
      transaction_date: Date.new(@year, 9, 1), transaction_value: 400_000, payment_method: "WIRE")

    assert_equal baseline + 1, @survey.air117
  end

  # Q159 — aIR2391: Has the State of Monaco pre-empted properties for sale?
  test "air2391 returns setting value for monaco_preempted_properties" do
    assert_nil @survey.air2391

    Setting.create!(organization: @organization, key: "monaco_preempted_properties", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.air2391
  end

  # Q160 — aIR2392: How many properties were pre-empted by Monaco?
  test "air2392 returns nil when air2391 is not Oui" do
    assert_nil @survey.air2392
  end

  test "air2392 returns setting value when air2391 is Oui" do
    Setting.create!(organization: @organization, key: "monaco_preempted_properties", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "monaco_preempted_property_count", category: "entity_info", value: "3")

    assert_equal "3", @survey.air2392
  end

  # Q161 — aIR2393: What was the total value of pre-empted properties?
  test "air2393 returns nil when air2391 is not Oui" do
    assert_nil @survey.air2393
  end

  test "air2393 returns setting value when air2391 is Oui" do
    Setting.create!(organization: @organization, key: "monaco_preempted_properties", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "monaco_preempted_property_value", category: "entity_info", value: "2500000")

    assert_equal "2500000", @survey.air2393
  end

  # Q162 — aIR234: Total unique properties rented in the reporting period
  test "air234 counts unique managed properties active in the year" do
    baseline = @survey.air234 || 0

    client = Client.create!(organization: @organization, name: "Landlord", client_type: "NATURAL_PERSON", nationality: "MC")

    # Active in year
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "1 Rue Test", management_start_date: Date.new(@year - 1, 6, 1),
      monthly_rent: 15_000, management_fee_percent: 5, property_type: "RESIDENTIAL")
    # Ended before year
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "2 Rue Test", management_start_date: Date.new(@year - 3, 1, 1),
      management_end_date: Date.new(@year - 1, 12, 31),
      monthly_rent: 8_000, management_fee_percent: 5, property_type: "RESIDENTIAL")
    # Started during year
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "3 Rue Test", management_start_date: Date.new(@year, 6, 1),
      monthly_rent: 5_000, management_fee_percent: 5, property_type: "COMMERCIAL")

    assert_equal baseline + 2, @survey.air234  # 2 active in year (1st and 3rd)
  end

  # Q163 — aIR236: Total rental operations in the reporting period
  test "air236 counts rental transactions in the year" do
    baseline = @survey.air236 || 0

    client = Client.create!(organization: @organization, name: "Tenant", client_type: "NATURAL_PERSON", nationality: "MC")

    Transaction.create!(organization: @organization, client: client, transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 3, 1), transaction_value: 120_000, payment_method: "WIRE")
    Transaction.create!(organization: @organization, client: client, transaction_type: "RENTAL",
      transaction_date: Date.new(@year, 9, 1), transaction_value: 60_000, payment_method: "WIRE")
    # PURCHASE should not count
    Transaction.create!(organization: @organization, client: client, transaction_type: "PURCHASE",
      transaction_date: Date.new(@year, 6, 1), transaction_value: 500_000, payment_method: "WIRE")

    assert_equal baseline + 2, @survey.air236
  end

  # Q164 — aIR2313: Unique rental properties >= 10,000 EUR/month
  test "air2313 counts managed properties with monthly rent >= 10000 active in year" do
    baseline = @survey.air2313 || 0

    client = Client.create!(organization: @organization, name: "Landlord", client_type: "NATURAL_PERSON", nationality: "MC")

    # >= 10k (should count)
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "1 Rue High", management_start_date: Date.new(@year - 1, 1, 1),
      monthly_rent: 15_000, management_fee_percent: 5, property_type: "RESIDENTIAL")
    # Exactly 10k (should count)
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "2 Rue Threshold", management_start_date: Date.new(@year, 3, 1),
      monthly_rent: 10_000, management_fee_percent: 5, property_type: "RESIDENTIAL")
    # < 10k (should not count)
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "3 Rue Low", management_start_date: Date.new(@year, 6, 1),
      monthly_rent: 5_000, management_fee_percent: 5, property_type: "COMMERCIAL")

    assert_equal baseline + 2, @survey.air2313
  end

  # Q165 — aIR2316: Unique rental properties < 10,000 EUR/month
  test "air2316 counts managed properties with monthly rent < 10000 active in year" do
    baseline = @survey.air2316 || 0

    client = Client.create!(organization: @organization, name: "Landlord", client_type: "NATURAL_PERSON", nationality: "MC")

    # < 10k (should count)
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "1 Rue Low", management_start_date: Date.new(@year, 1, 1),
      monthly_rent: 5_000, management_fee_percent: 5, property_type: "RESIDENTIAL")
    # >= 10k (should not count)
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "2 Rue High", management_start_date: Date.new(@year, 3, 1),
      monthly_rent: 15_000, management_fee_percent: 5, property_type: "RESIDENTIAL")
    # Exactly 10k (should not count — boundary is strict <)
    ManagedProperty.create!(organization: @organization, client: client,
      property_address: "3 Rue Threshold", management_start_date: Date.new(@year, 6, 1),
      monthly_rent: 10_000, management_fee_percent: 5, property_type: "COMMERCIAL")

    assert_equal baseline + 1, @survey.air2316
  end

  # Q166 — a2501A: Does entity have comments on products/services section?
  test "a2501a returns setting value for has_products_services_comments" do
    assert_nil @survey.a2501a

    Setting.create!(organization: @organization, key: "has_products_services_comments", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a2501a
  end

  # Q167 — a2501: Products/services section comments text
  test "a2501 returns nil when a2501a is not Oui" do
    assert_nil @survey.a2501
  end

  test "a2501 returns setting value when a2501a is Oui" do
    Setting.create!(organization: @organization, key: "has_products_services_comments", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "products_services_comments", category: "entity_info", value: "Some comments about products and services risk")
    assert_equal "Some comments about products and services risk", @survey.a2501
  end

  # Q168 — a3101: Does entity use local third parties for CDD?
  test "a3101 returns setting value for uses_local_third_party_cdd" do
    assert_nil @survey.a3101

    Setting.create!(organization: @organization, key: "uses_local_third_party_cdd", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3101
  end

  # Q169 — a3102: Clients with local third-party CDD, by nationality (dimensional)
  test "a3102 returns nil when a3101 is not Oui" do
    assert_nil @survey.a3102
  end

  test "a3102 returns client count by nationality for local third-party CDD" do
    Setting.create!(organization: @organization, key: "uses_local_third_party_cdd", category: "entity_info", value: "Oui")
    baseline = @survey.a3102

    # NP with local third-party CDD
    Client.create!(organization: @organization, name: "Local CDD NP", client_type: "NATURAL_PERSON",
      nationality: "FR", third_party_cdd: true, third_party_cdd_type: "LOCAL")

    # LE with local third-party CDD
    Client.create!(organization: @organization, name: "Local CDD LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "IT",
      third_party_cdd: true, third_party_cdd_type: "LOCAL")

    # NP with foreign third-party CDD (should NOT count)
    Client.create!(organization: @organization, name: "Foreign CDD NP", client_type: "NATURAL_PERSON",
      nationality: "FR", third_party_cdd: true, third_party_cdd_type: "FOREIGN", third_party_cdd_country: "GB")

    # NP without third-party CDD (should NOT count)
    Client.create!(organization: @organization, name: "No CDD NP", client_type: "NATURAL_PERSON",
      nationality: "FR")

    result = @survey.a3102
    assert_equal (baseline["FR"] || 0) + 1, result["FR"]
    assert_equal (baseline["IT"] || 0) + 1, result["IT"]
  end

  # Q170 — a3103: Does entity use foreign third parties for CDD?
  test "a3103 returns setting value for uses_foreign_third_party_cdd" do
    assert_nil @survey.a3103

    Setting.create!(organization: @organization, key: "uses_foreign_third_party_cdd", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3103
  end

  # Q171 — a3104: Clients with foreign third-party CDD, by nationality (dimensional)
  test "a3104 returns nil when a3103 is not Oui" do
    assert_nil @survey.a3104
  end

  test "a3104 returns client count by nationality for foreign third-party CDD" do
    Setting.create!(organization: @organization, key: "uses_foreign_third_party_cdd", category: "entity_info", value: "Oui")
    baseline = @survey.a3104

    # NP with foreign third-party CDD
    Client.create!(organization: @organization, name: "Foreign CDD NP", client_type: "NATURAL_PERSON",
      nationality: "DE", third_party_cdd: true, third_party_cdd_type: "FOREIGN", third_party_cdd_country: "GB")

    # LE with foreign third-party CDD
    Client.create!(organization: @organization, name: "Foreign CDD LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "CH",
      third_party_cdd: true, third_party_cdd_type: "FOREIGN", third_party_cdd_country: "FR")

    # NP with local third-party CDD (should NOT count)
    Client.create!(organization: @organization, name: "Local CDD NP", client_type: "NATURAL_PERSON",
      nationality: "DE", third_party_cdd: true, third_party_cdd_type: "LOCAL")

    result = @survey.a3104
    assert_equal (baseline["DE"] || 0) + 1, result["DE"]
    assert_equal (baseline["CH"] || 0) + 1, result["CH"]
  end

  # Q172 — a3105: Clients with foreign third-party CDD, by third-party country (dimensional)
  test "a3105 returns nil when a3103 is not Oui" do
    assert_nil @survey.a3105
  end

  test "a3105 returns client count by third-party country for foreign CDD" do
    Setting.create!(organization: @organization, key: "uses_foreign_third_party_cdd", category: "entity_info", value: "Oui")
    baseline = @survey.a3105

    # Client with foreign third-party CDD in GB
    Client.create!(organization: @organization, name: "Foreign CDD 1", client_type: "NATURAL_PERSON",
      nationality: "FR", third_party_cdd: true, third_party_cdd_type: "FOREIGN", third_party_cdd_country: "GB")

    # Client with foreign third-party CDD in CH
    Client.create!(organization: @organization, name: "Foreign CDD 2", client_type: "NATURAL_PERSON",
      nationality: "DE", third_party_cdd: true, third_party_cdd_type: "FOREIGN", third_party_cdd_country: "CH")

    # Client with local CDD (should NOT count)
    Client.create!(organization: @organization, name: "Local CDD", client_type: "NATURAL_PERSON",
      nationality: "FR", third_party_cdd: true, third_party_cdd_type: "LOCAL")

    result = @survey.a3105
    assert_equal (baseline["GB"] || 0) + 1, result["GB"]
    assert_equal (baseline["CH"] || 0) + 1, result["CH"]
  end

  # Q173 — aB3206: New NP clients onboarded during reporting period
  test "ab3206 counts new natural person clients onboarded in reporting year" do
    baseline = @survey.ab3206

    # NP onboarded in reporting year (counts)
    Client.create!(organization: @organization, name: "New NP", client_type: "NATURAL_PERSON",
      nationality: "FR", became_client_at: Date.new(@year, 6, 15))

    # NP onboarded in previous year (does NOT count)
    Client.create!(organization: @organization, name: "Old NP", client_type: "NATURAL_PERSON",
      nationality: "DE", became_client_at: Date.new(@year - 1, 3, 1))

    # LE onboarded in reporting year (does NOT count — not NP)
    Client.create!(organization: @organization, name: "New LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "IT",
      became_client_at: Date.new(@year, 9, 1))

    assert_equal baseline + 1, @survey.ab3206
  end

  # Q174 — aB3207: New legal entity clients (excl. trusts) onboarded during reporting period
  test "ab3207 counts new legal entity clients excl trusts onboarded in reporting year" do
    baseline = @survey.ab3207

    # LE (non-trust) onboarded in reporting year (counts)
    Client.create!(organization: @organization, name: "New LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "MC",
      became_client_at: Date.new(@year, 3, 1))

    # Trust onboarded in reporting year (does NOT count — trust is separate)
    Client.create!(organization: @organization, name: "New Trust", client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST", incorporation_country: "JE",
      became_client_at: Date.new(@year, 6, 1))

    # LE onboarded in previous year (does NOT count)
    Client.create!(organization: @organization, name: "Old LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SA", incorporation_country: "FR",
      became_client_at: Date.new(@year - 1, 12, 1))

    assert_equal baseline + 1, @survey.ab3207
  end

  # Q175 — a3208TOLA: New trust/legal construction clients onboarded during reporting period
  test "a3208tola counts new trust clients onboarded in reporting year" do
    baseline = @survey.a3208tola

    # Trust onboarded in reporting year (counts)
    Client.create!(organization: @organization, name: "New Trust", client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST", incorporation_country: "JE",
      became_client_at: Date.new(@year, 4, 1))

    # Non-trust LE onboarded in reporting year (does NOT count)
    Client.create!(organization: @organization, name: "New LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "MC",
      became_client_at: Date.new(@year, 5, 1))

    # Trust onboarded in previous year (does NOT count)
    Client.create!(organization: @organization, name: "Old Trust", client_type: "LEGAL_ENTITY",
      legal_entity_type: "TRUST", incorporation_country: "GG",
      became_client_at: Date.new(@year - 1, 6, 1))

    assert_equal baseline + 1, @survey.a3208tola
  end

  # Q176 — a3209: Does entity onboard clients without face-to-face?
  test "a3209 returns setting value for non_face_to_face_onboarding" do
    assert_nil @survey.a3209

    Setting.create!(organization: @organization, key: "non_face_to_face_onboarding", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3209
  end

  # Q177 — a3210C: NP clients onboarded without face-to-face
  test "a3210c returns nil when a3209 is not Oui" do
    assert_nil @survey.a3210c
  end

  test "a3210c returns setting value when a3209 is Oui" do
    Setting.create!(organization: @organization, key: "non_face_to_face_onboarding", category: "entity_info", value: "Oui")
    assert_nil @survey.a3210c

    Setting.create!(organization: @organization, key: "non_face_to_face_np_onboarded_count", category: "entity_info", value: "5")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "5", @survey.a3210c
  end

  # Q178 — a3211C: LP clients onboarded without face-to-face
  test "a3211c returns nil when a3209 is not Oui" do
    assert_nil @survey.a3211c
  end

  test "a3211c returns setting value when a3209 is Oui" do
    Setting.create!(organization: @organization, key: "non_face_to_face_onboarding", category: "entity_info", value: "Oui")
    assert_nil @survey.a3211c

    Setting.create!(organization: @organization, key: "non_face_to_face_lp_onboarded_count", category: "entity_info", value: "3")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "3", @survey.a3211c
  end

  # Q179 — a3212CTOLA: Trust clients onboarded without face-to-face
  test "a3212ctola returns nil when a3209 is not Oui" do
    assert_nil @survey.a3212ctola
  end

  test "a3212ctola returns setting value when both conditions met" do
    Setting.create!(organization: @organization, key: "non_face_to_face_onboarding", category: "entity_info", value: "Oui")

    assert_nil @survey.a3212ctola

    Setting.create!(organization: @organization, key: "non_face_to_face_trust_onboarded_count", category: "entity_info", value: "2")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "2", @survey.a3212ctola
  end

  # Q180 — a3201: Entity accepts clients through introducers
  test "a3201 returns setting value for accepts_clients_through_introducers" do
    assert_nil @survey.a3201

    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3201
  end

  # Q181 — a3501B: Can entity provide nationality info for introduced clients?
  test "a3501b returns nil when a3201 is not Oui" do
    assert_nil @survey.a3501b
  end

  test "a3501b returns setting value when a3201 is Oui" do
    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    assert_nil @survey.a3501b

    Setting.create!(organization: @organization, key: "can_provide_introducer_client_nationality", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3501b
  end

  # Q182 — a3202: Introduced clients by primary nationality (dimensional)
  test "a3202 returns nil when a3501b is not Oui" do
    assert_nil @survey.a3202
  end

  test "a3202 returns introduced clients grouped by country" do
    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_provide_introducer_client_nationality", category: "entity_info", value: "Oui")
    baseline = @survey.a3202

    # Introduced NP (nationality FR) — counts
    Client.create!(organization: @organization, name: "Intro NP", client_type: "NATURAL_PERSON",
      nationality: "FR", introduced_by_third_party: true, introducer_country: "MC")

    # Introduced LE (incorporation_country LU) — counts
    Client.create!(organization: @organization, name: "Intro LE", client_type: "LEGAL_ENTITY",
      legal_entity_type: "SARL", incorporation_country: "LU",
      introduced_by_third_party: true, introducer_country: "MC")

    # Not introduced (does NOT count)
    Client.create!(organization: @organization, name: "Direct NP", client_type: "NATURAL_PERSON",
      nationality: "FR")

    result = @survey.a3202
    assert_equal (baseline["FR"] || 0) + 1, result["FR"]
    assert_equal (baseline["LU"] || 0) + 1, result["LU"]
  end

  # Q183 — a3204: Introduced clients in reporting period by primary nationality (dimensional)
  test "a3204 returns nil when a3501b is not Oui" do
    assert_nil @survey.a3204
  end

  test "a3204 returns introduced clients in reporting period grouped by country" do
    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_provide_introducer_client_nationality", category: "entity_info", value: "Oui")
    baseline = @survey.a3204

    # Introduced NP in reporting year (counts)
    Client.create!(organization: @organization, name: "New Intro NP", client_type: "NATURAL_PERSON",
      nationality: "IT", introduced_by_third_party: true, introducer_country: "MC",
      became_client_at: Date.new(@year, 3, 1))

    # Introduced NP in previous year (does NOT count)
    Client.create!(organization: @organization, name: "Old Intro NP", client_type: "NATURAL_PERSON",
      nationality: "IT", introduced_by_third_party: true, introducer_country: "MC",
      became_client_at: Date.new(@year - 1, 6, 1))

    result = @survey.a3204
    assert_equal (baseline["IT"] || 0) + 1, result["IT"]
  end

  # Q184 — a3501C: Can entity provide residence info for introducers?
  test "a3501c returns nil when a3201 is not Oui" do
    assert_nil @survey.a3501c
  end

  test "a3501c returns setting value when a3201 is Oui" do
    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    assert_nil @survey.a3501c

    Setting.create!(organization: @organization, key: "can_provide_introducer_residence", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3501c
  end

  # Q185 — a3203: Introduced clients by introducer residence (dimensional)
  test "a3203 returns nil when a3501c is not Oui" do
    assert_nil @survey.a3203
  end

  test "a3203 returns introduced clients grouped by introducer country" do
    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_provide_introducer_residence", category: "entity_info", value: "Oui")
    baseline = @survey.a3203

    # Introduced by MC-based introducer (counts)
    Client.create!(organization: @organization, name: "Intro Client 1", client_type: "NATURAL_PERSON",
      nationality: "FR", introduced_by_third_party: true, introducer_country: "MC")

    # Introduced by FR-based introducer (counts)
    Client.create!(organization: @organization, name: "Intro Client 2", client_type: "NATURAL_PERSON",
      nationality: "IT", introduced_by_third_party: true, introducer_country: "FR")

    # Not introduced (does NOT count)
    Client.create!(organization: @organization, name: "Direct Client", client_type: "NATURAL_PERSON",
      nationality: "FR")

    result = @survey.a3203
    assert_equal (baseline["MC"] || 0) + 1, result["MC"]
    assert_equal (baseline["FR"] || 0) + 1, result["FR"]
  end

  # Q186 — a3205: Introduced clients in reporting period by introducer residence (dimensional)
  test "a3205 returns nil when a3501c is not Oui" do
    assert_nil @survey.a3205
  end

  test "a3205 returns introduced clients in reporting period grouped by introducer country" do
    Setting.create!(organization: @organization, key: "accepts_clients_through_introducers", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "can_provide_introducer_residence", category: "entity_info", value: "Oui")
    baseline = @survey.a3205

    # Introduced in reporting year by MC-based introducer (counts)
    Client.create!(organization: @organization, name: "New Intro 1", client_type: "NATURAL_PERSON",
      nationality: "FR", introduced_by_third_party: true, introducer_country: "MC",
      became_client_at: Date.new(@year, 5, 1))

    # Introduced in previous year (does NOT count)
    Client.create!(organization: @organization, name: "Old Intro 1", client_type: "NATURAL_PERSON",
      nationality: "IT", introduced_by_third_party: true, introducer_country: "MC",
      became_client_at: Date.new(@year - 1, 5, 1))

    result = @survey.a3205
    assert_equal (baseline["MC"] || 0) + 1, result["MC"]
  end

  # Q187 — aIR33LF: Legal form of entity
  test "air33lf returns setting value for entity_legal_form" do
    assert_nil @survey.air33lf

    Setting.create!(organization: @organization, key: "entity_legal_form", category: "entity_info", value: "13. Sociétés à responsabilité limitée")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "13. Sociétés à responsabilité limitée", @survey.air33lf
  end

  # Q188 — aIR328: Is professional card holder a legal entity?
  test "air328 returns setting value for card_holder_is_legal_entity" do
    assert_nil @survey.air328

    Setting.create!(organization: @organization, key: "card_holder_is_legal_entity", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.air328
  end

  # Q189 — a3301: Total employee headcount
  test "a3301 returns setting value for total_employee_headcount" do
    assert_nil @survey.a3301

    Setting.create!(organization: @organization, key: "total_employee_headcount", category: "entity_info", value: "15")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "15", @survey.a3301
  end

  # Q190 — a3302: Does entity have branches, subsidiaries, or agencies?
  test "a3302 returns setting value for has_branches" do
    assert_nil @survey.a3302

    Setting.create!(organization: @organization, key: "has_branches", category: "entity_info", value: "Non")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Non", @survey.a3302
  end

  # Q191 — a3303: Total branches by country (dimensional)
  test "a3303 returns nil when a3302 is not Oui" do
    assert_nil @survey.a3303
  end

  test "a3303 returns parsed JSON hash when a3302 is Oui" do
    Setting.create!(organization: @organization, key: "has_branches", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "branches_by_country", category: "entity_info", value: '{"MC":2,"FR":1}')

    assert_equal({"MC" => 2, "FR" => 1}, @survey.a3303)
  end

  # Q193 — a3304C: Is entity a branch or subsidiary of another entity?
  test "a3304c returns setting value for is_branch_of_another_entity" do
    assert_nil @survey.a3304c

    Setting.create!(organization: @organization, key: "is_branch_of_another_entity", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3304c
  end

  # Q192 — a3304: Is entity a branch or subsidiary of a foreign entity?
  test "a3304 returns nil when a3304c is not Oui" do
    assert_nil @survey.a3304
  end

  test "a3304 returns setting value when a3304c is Oui" do
    Setting.create!(organization: @organization, key: "is_branch_of_another_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "is_branch_of_foreign_entity", category: "entity_info", value: "Oui")
    assert_equal "Oui", @survey.a3304
  end

  # Q194 — a3305: Parent company country
  test "a3305 returns nil when a3304 is not Oui" do
    assert_nil @survey.a3305
  end

  test "a3305 returns setting value when a3304 is Oui" do
    Setting.create!(organization: @organization, key: "is_branch_of_another_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "is_branch_of_foreign_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "parent_company_country", category: "entity_info", value: "France")
    assert_equal "France", @survey.a3305
  end

  # Q195 — a3306: Total foreign branches count
  test "a3306 returns nil when a3304 is not Oui" do
    assert_nil @survey.a3306
  end

  test "a3306 returns setting value when a3304 is Oui" do
    Setting.create!(organization: @organization, key: "is_branch_of_another_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "is_branch_of_foreign_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "total_foreign_branches", category: "entity_info", value: "3")
    assert_equal "3", @survey.a3306
  end

  # Q196 — a3306A: Shareholders 25%+ by nationality (dimensional)
  test "a3306a returns nil when air328 is not Oui" do
    assert_nil @survey.a3306a
  end

  test "a3306a returns parsed JSON hash when air328 is Oui" do
    Setting.create!(organization: @organization, key: "card_holder_is_legal_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "shareholders_25pct_by_nationality", category: "entity_info", value: '{"MC":2,"FR":1}')
    assert_equal({"MC" => 2, "FR" => 1}, @survey.a3306a)
  end

  # Q197 — a3306B: BOs with 25%+ by nationality (dimensional)
  test "a3306b returns nil when air328 is not Oui" do
    assert_nil @survey.a3306b
  end

  test "a3306b returns parsed JSON hash when air328 is Oui" do
    Setting.create!(organization: @organization, key: "card_holder_is_legal_entity", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "bos_25pct_by_nationality", category: "entity_info", value: '{"MC":1,"IT":2}')
    assert_equal({"MC" => 1, "IT" => 2}, @survey.a3306b)
  end

  # Q198 — a3307: Changes in structure during reporting period?
  test "a3307 returns setting value for structural_changes_during_period" do
    assert_nil @survey.a3307

    Setting.create!(organization: @organization, key: "structural_changes_during_period", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3307
  end

  # Q199 — a3308: Describe structural changes
  test "a3308 returns nil when a3307 is not Oui" do
    assert_nil @survey.a3308
  end

  test "a3308 returns setting value when a3307 is Oui" do
    Setting.create!(organization: @organization, key: "structural_changes_during_period", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "structural_changes_description", category: "entity_info", value: "New director appointed")
    assert_equal "New director appointed", @survey.a3308
  end

  # Q200 — a3210B: Part of international business network?
  test "a3210b returns setting value for part_of_international_network" do
    assert_nil @survey.a3210b

    Setting.create!(organization: @organization, key: "part_of_international_network", category: "entity_info", value: "Non")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Non", @survey.a3210b
  end

  # Q201 — a3211B: Specify international network
  test "a3211b returns nil when a3210b is not Oui" do
    assert_nil @survey.a3211b
  end

  test "a3211b returns setting value when a3210b is Oui" do
    Setting.create!(organization: @organization, key: "part_of_international_network", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "international_network_name", category: "entity_info", value: "Sotheby's International Realty")
    assert_equal "Sotheby's International Realty", @survey.a3211b
  end

  # Q202 — a3210: Member of professional association?
  test "a3210 returns setting value for member_of_professional_association" do
    assert_nil @survey.a3210

    Setting.create!(organization: @organization, key: "member_of_professional_association", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3210
  end

  # Q203 — a3211: Specify professional association
  test "a3211 returns nil when a3210 is not Oui" do
    assert_nil @survey.a3211
  end

  test "a3211 returns setting value when a3210 is Oui" do
    Setting.create!(organization: @organization, key: "member_of_professional_association", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "professional_association_name", category: "entity_info", value: "Chambre Immobilière Monégasque")
    assert_equal "Chambre Immobilière Monégasque", @survey.a3211
  end

  # Q204 — a381: Revenue for reporting period (monetaryItemType)
  test "a381 returns setting value for revenue" do
    assert_nil @survey.a381

    Setting.create!(organization: @organization, key: "revenue_reporting_period", category: "entity_info", value: "1500000.00")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "1500000.00", @survey.a381
  end

  # Q205 — a3802: Revenue in Monaco (monetaryItemType)
  test "a3802 returns setting value for revenue in Monaco" do
    assert_nil @survey.a3802

    Setting.create!(organization: @organization, key: "revenue_in_monaco", category: "entity_info", value: "1200000.00")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "1200000.00", @survey.a3802
  end

  # Q206 — a3803: Revenue outside Monaco (monetaryItemType)
  test "a3803 returns setting value for revenue outside Monaco" do
    assert_nil @survey.a3803

    Setting.create!(organization: @organization, key: "revenue_outside_monaco", category: "entity_info", value: "300000.00")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "300000.00", @survey.a3803
  end

  # Q207 — a3804: Annual VAT declaration amount (monetaryItemType)
  test "a3804 returns setting value for annual VAT declaration" do
    assert_nil @survey.a3804

    Setting.create!(organization: @organization, key: "annual_vat_declaration_amount", category: "entity_info", value: "75000.00")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "75000.00", @survey.a3804
  end

  # Q208 — a3401: Total rejected prospects count
  test "a3401 returns setting value for rejected prospects" do
    assert_nil @survey.a3401

    Setting.create!(organization: @organization, key: "rejected_prospects_count", category: "entity_info", value: "3")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "3", @survey.a3401
  end

  # Q209 — a3402: Can entity distinguish rejection reasons?
  test "a3402 returns setting value for can_distinguish_rejection_reasons" do
    assert_nil @survey.a3402

    Setting.create!(organization: @organization, key: "can_distinguish_rejection_reasons", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3402
  end

  # Q210 — a3403: Rejected prospects due to client attributes (conditional on a3402)
  test "a3403 returns nil when a3402 is not Oui" do
    assert_nil @survey.a3403
  end

  test "a3403 returns setting value when a3402 is Oui" do
    Setting.create!(organization: @organization, key: "can_distinguish_rejection_reasons", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "rejected_prospects_client_attribute_count", category: "entity_info", value: "2")
    assert_equal "2", @survey.a3403
  end

  # Q211 — a3414: Total terminated client relationships
  test "a3414 returns setting value for terminated relationships" do
    assert_nil @survey.a3414

    Setting.create!(organization: @organization, key: "terminated_relationships_count", category: "entity_info", value: "1")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "1", @survey.a3414
  end

  # Q212 — a3415: Can entity distinguish termination reasons?
  test "a3415 returns setting value for can_distinguish_termination_reasons" do
    assert_nil @survey.a3415

    Setting.create!(organization: @organization, key: "can_distinguish_termination_reasons", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3415
  end

  # Q213 — a3416: Terminated relationships due to client attributes (conditional on a3415)
  test "a3416 returns nil when a3415 is not Oui" do
    assert_nil @survey.a3416
  end

  test "a3416 returns setting value when a3415 is Oui" do
    Setting.create!(organization: @organization, key: "can_distinguish_termination_reasons", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "terminated_relationships_client_attribute_count", category: "entity_info", value: "1")
    assert_equal "1", @survey.a3416
  end

  # Q214 — a3701A: Has comments on distribution risk section?
  test "a3701a returns setting value for has_distribution_risk_comments" do
    assert_nil @survey.a3701a

    Setting.create!(organization: @organization, key: "has_distribution_risk_comments", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.a3701a
  end

  # Q215 — a3701: Distribution risk section comments (conditional on a3701A)
  test "a3701 returns nil when a3701a is not Oui" do
    assert_nil @survey.a3701
  end

  test "a3701 returns setting value when a3701a is Oui" do
    Setting.create!(organization: @organization, key: "has_distribution_risk_comments", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "distribution_risk_comments", category: "entity_info", value: "No additional comments.")
    assert_equal "No additional comments.", @survey.a3701
  end

  # === PART 2: CONTROLS ===

  # C1 — aC1102A: Total employees (reuses a3301)
  test "ac1102a returns setting value for total_employee_headcount" do
    assert_nil @survey.ac1102a

    Setting.create!(organization: @organization, key: "total_employee_headcount", category: "entity_info", value: "12")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "12", @survey.ac1102a
  end

  # C2 — aC1102: FTE employees
  test "ac1102 returns setting value for fte_employees" do
    assert_nil @survey.ac1102

    Setting.create!(organization: @organization, key: "fte_employees", category: "entity_info", value: "10.5")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "10.5", @survey.ac1102
  end

  # C3 — aC1101Z: Hours on AML/CFT compliance per month
  test "ac1101z returns setting value for aml_compliance_hours_per_month" do
    assert_nil @survey.ac1101z

    Setting.create!(organization: @organization, key: "aml_compliance_hours_per_month", category: "compliance_policies", value: "40.0")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "40.0", @survey.ac1101z
  end

  # C4 — aC114: Has board/senior management?
  test "ac114 returns setting value for has_board_or_senior_management" do
    assert_nil @survey.ac114

    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.ac114
  end

  # C5 — aC1106: Has compliance department?
  test "ac1106 returns setting value for has_compliance_department" do
    assert_nil @survey.ac1106

    Setting.create!(organization: @organization, key: "has_compliance_department", category: "compliance_policies", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.ac1106
  end

  # C6 — aC1518A: Entity is part of a group?
  test "ac1518a returns setting value for entity_is_part_of_group" do
    assert_nil @survey.ac1518a

    Setting.create!(organization: @organization, key: "entity_is_part_of_group", category: "entity_info", value: "Non")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Non", @survey.ac1518a
  end

  # C7 — aC1201: Has written AML/CFT policies and procedures?
  test "ac1201 returns setting value for has_written_aml_policies" do
    assert_nil @survey.ac1201

    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    @survey = Survey.new(organization: @organization, year: @year)
    assert_equal "Oui", @survey.ac1201
  end

  # C8 — aC1202: Policies approved by board/senior management? (conditional on aC114)
  test "ac1202 returns nil when ac114 is not Oui" do
    assert_nil @survey.ac1202
  end

  test "ac1202 returns setting value when ac114 is Oui" do
    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "policies_approved_by_board", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1202
  end

  # C9 — aC1203: Policies disseminated to all employees? (conditional on aC1201)
  test "ac1203 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1203
  end

  test "ac1203 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "policies_disseminated_to_employees", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1203
  end

  # C10 — aC1204: Ensured employees know the policies? (conditional on aC1201)
  test "ac1204 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1204
  end

  test "ac1204 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "employees_aware_of_policies", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1204
  end

  # C11 — aC1205: Updated AML/CFT policies in past year? (conditional on aC1201)
  test "ac1205 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1205
  end

  test "ac1205 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "policies_updated_past_year", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1205
  end

  # C12 — aC1206: Date of last policy update (conditional on aC1201)
  test "ac1206 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1206
  end

  test "ac1206 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "last_policy_update_date", category: "compliance_policies", value: "2025-06-15")
    assert_equal "2025-06-15", @survey.ac1206
  end

  # C13 — aC1207: Systematic tracking of policy changes? (conditional on aC1201)
  test "ac1207 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1207
  end

  test "ac1207 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "systematic_policy_change_tracking", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1207
  end

  # C14 — aC1209B: Has group-wide AML/CFT program? (conditional on aC1518A)
  test "ac1209b returns nil when ac1518a is not Oui" do
    assert_nil @survey.ac1209b
  end

  test "ac1209b returns setting value when ac1518a is Oui" do
    Setting.create!(organization: @organization, key: "entity_is_part_of_group", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_group_aml_program", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1209b
  end

  # C15 — aC1209C: Analyzed group AML program for local compliance? (conditional on aC1209B)
  test "ac1209c returns nil when ac1209b is not Oui" do
    assert_nil @survey.ac1209c
  end

  test "ac1209c returns setting value when ac1209b is Oui" do
    Setting.create!(organization: @organization, key: "entity_is_part_of_group", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "has_group_aml_program", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "group_aml_program_compliance_analyzed", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1209c
  end

  # C16 — aC1208: Who prepared the policies? (conditional on aC1201)
  test "ac1208 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1208
  end

  test "ac1208 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "policy_preparer", category: "compliance_policies", value: "Par l'entité")
    assert_equal "Par l'entité", @survey.ac1208
  end

  # C17 — aC1209: Has self-assessed AML/CFT procedures adequacy? (conditional on aC1201)
  test "ac1209 returns nil when ac1201 is not Oui" do
    assert_nil @survey.ac1209
  end

  test "ac1209 returns setting value when ac1201 is Oui" do
    Setting.create!(organization: @organization, key: "has_written_aml_policies", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "self_assessed_aml_adequacy", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1209
  end

  # C18 — aC1301: Board/senior management demonstrates overall AML/CFT responsibility? (conditional on aC114)
  test "ac1301 returns nil when ac114 is not Oui" do
    assert_nil @survey.ac1301
  end

  test "ac1301 returns setting value when ac114 is Oui" do
    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "board_demonstrates_aml_responsibility", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1301
  end

  # C19 — aC1302: Board/senior management receives regular AML/CFT reports? (conditional on aC114)
  test "ac1302 returns nil when ac114 is not Oui" do
    assert_nil @survey.ac1302
  end

  test "ac1302 returns setting value when ac114 is Oui" do
    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "board_receives_aml_reports", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1302
  end

  # C20 — aC1303: Board/senior management ensures AML/CFT shortcomings are corrected? (conditional on aC114)
  test "ac1303 returns nil when ac114 is not Oui" do
    assert_nil @survey.ac1303
  end

  test "ac1303 returns setting value when ac114 is Oui" do
    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "board_corrects_aml_shortcomings", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1303
  end

  # C21 — aC1304: Senior management approves high-risk client acceptance? (conditional on aC114)
  test "ac1304 returns nil when ac114 is not Oui" do
    assert_nil @survey.ac1304
  end

  test "ac1304 returns setting value when ac114 is Oui" do
    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "senior_mgmt_approves_high_risk_clients", category: "compliance_policies", value: "Oui")
    assert_equal "Oui", @survey.ac1304
  end

  # C22 — aC1401: Entity had AML/CFT violations in past 5 years? (enum Oui/Non, unconditional)
  test "ac1401 returns nil when no setting exists" do
    assert_nil @survey.ac1401
  end

  test "ac1401 returns setting value" do
    Setting.create!(organization: @organization, key: "had_aml_violations_past_5_years", category: "compliance_policies", value: "Non")
    assert_equal "Non", @survey.ac1401
  end

  # C23 — aC1402: Total AML/CFT violations in past 5 years (integerItemType, conditional on aC1401)
  test "ac1402 returns nil when ac1401 is not Oui" do
    assert_nil @survey.ac1402
  end

  test "ac1402 returns setting value when ac1401 is Oui" do
    Setting.create!(organization: @organization, key: "had_aml_violations_past_5_years", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "aml_violations_count_past_5_years", category: "compliance_policies", value: "3")
    assert_equal "3", @survey.ac1402
  end

  # C24 — aC1403: Number and type of AML/CFT violations (stringItemType, conditional on aC1401)
  test "ac1403 returns nil when ac1401 is not Oui" do
    assert_nil @survey.ac1403
  end

  test "ac1403 returns setting value when ac1401 is Oui" do
    Setting.create!(organization: @organization, key: "had_aml_violations_past_5_years", category: "compliance_policies", value: "Oui")
    Setting.create!(organization: @organization, key: "aml_violations_description", category: "compliance_policies", value: "2 documentation gaps, 1 late filing")
    assert_equal "2 documentation gaps, 1 late filing", @survey.ac1403
  end

  # C25 — aC1501: AML/CFT training provided to directors/management? (conditional on aC114)
  test "ac1501 returns nil when ac114 is not Oui" do
    assert_nil @survey.ac1501
  end

  test "ac1501 returns setting value when ac114 is Oui" do
    Setting.create!(organization: @organization, key: "has_board_or_senior_management", category: "entity_info", value: "Oui")
    Setting.create!(organization: @organization, key: "aml_training_provided_to_directors", category: "training", value: "Oui")
    assert_equal "Oui", @survey.ac1501
  end

  # C26 — aC1503B: AML/CFT training provided to office employees? (enum Oui/Non, unconditional)
  test "ac1503b returns nil when no setting exists" do
    assert_nil @survey.ac1503b
  end

  test "ac1503b returns setting value" do
    Setting.create!(organization: @organization, key: "aml_training_provided_to_staff", category: "training", value: "Oui")
    assert_equal "Oui", @survey.ac1503b
  end

  # C27 — aC1506: Total employees trained on AML/CFT (integerItemType, unconditional)
  test "ac1506 returns nil when no setting exists" do
    assert_nil @survey.ac1506
  end

  test "ac1506 returns setting value" do
    Setting.create!(organization: @organization, key: "total_employees_trained_aml", category: "training", value: "12")
    assert_equal "12", @survey.ac1506
  end

  # ============================================================
  # Section 1.6 — CDD (C28–C66)
  # ============================================================

  # C28 — aC1625: Records ID card info for NP clients? (enum Oui/Non)
  test "ac1625 returns nil when no setting exists" do
    assert_nil @survey.ac1625
  end

  test "ac1625 returns setting value" do
    Setting.create!(organization: @organization, key: "records_id_card_info", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1625
  end

  # C29 — aC1626: Records passport info? (enum Oui/Non)
  test "ac1626 returns nil when no setting exists" do
    assert_nil @survey.ac1626
  end

  test "ac1626 returns setting value" do
    Setting.create!(organization: @organization, key: "records_passport_info", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1626
  end

  # C30 — aC1627: Records residence permit info? (enum Oui/Non)
  test "ac1627 returns nil when no setting exists" do
    assert_nil @survey.ac1627
  end

  test "ac1627 returns setting value" do
    Setting.create!(organization: @organization, key: "records_residence_permit_info", category: "kyc_procedures", value: "Non")
    assert_equal "Non", @survey.ac1627
  end

  # C31 — aC168: Records proof of address? (enum Oui/Non)
  test "ac168 returns nil when no setting exists" do
    assert_nil @survey.ac168
  end

  test "ac168 returns setting value" do
    Setting.create!(organization: @organization, key: "records_proof_of_address", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac168
  end

  # C32 — aC1629: Records other individual info? (enum Oui/Non)
  test "ac1629 returns nil when no setting exists" do
    assert_nil @survey.ac1629
  end

  test "ac1629 returns setting value" do
    Setting.create!(organization: @organization, key: "records_other_individual_info", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1629
  end

  # C33 — aC1630: Specify other individual info (free text, conditional on aC1629)
  test "ac1630 returns nil when ac1629 is not Oui" do
    assert_nil @survey.ac1630
  end

  test "ac1630 returns setting value when ac1629 is Oui" do
    Setting.create!(organization: @organization, key: "records_other_individual_info", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "other_individual_info_details", category: "kyc_procedures", value: "Tax ID number")
    assert_equal "Tax ID number", @survey.ac1630
  end

  # C34 — aC1601: All required NP elements kept on file? (enum Oui/Non)
  test "ac1601 returns nil when no setting exists" do
    assert_nil @survey.ac1601
  end

  test "ac1601 returns setting value" do
    Setting.create!(organization: @organization, key: "all_np_elements_on_file", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1601
  end

  # C35 — aC1602: Specify which elements are not collected (free text, conditional on aC1601 == "Non")
  test "ac1602 returns nil when ac1601 is not Non" do
    assert_nil @survey.ac1602
  end

  test "ac1602 returns nil when ac1601 is Oui" do
    Setting.create!(organization: @organization, key: "all_np_elements_on_file", category: "kyc_procedures", value: "Oui")
    assert_nil @survey.ac1602
  end

  test "ac1602 returns setting value when ac1601 is Non" do
    Setting.create!(organization: @organization, key: "all_np_elements_on_file", category: "kyc_procedures", value: "Non")
    Setting.create!(organization: @organization, key: "missing_np_elements_description", category: "kyc_procedures", value: "Place of birth")
    assert_equal "Place of birth", @survey.ac1602
  end

  # C36 — aC1631: Records commercial registry extract for LE? (enum Oui/Non)
  test "ac1631 returns nil when no setting exists" do
    assert_nil @survey.ac1631
  end

  test "ac1631 returns setting value" do
    Setting.create!(organization: @organization, key: "records_commercial_registry_extract", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1631
  end

  # C37 — aC1633: Records articles of association for LE? (enum Oui/Non)
  test "ac1633 returns nil when no setting exists" do
    assert_nil @survey.ac1633
  end

  test "ac1633 returns setting value" do
    Setting.create!(organization: @organization, key: "records_articles_of_association", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1633
  end

  # C38 — aC1634: Records minutes of general assembly for LE? (enum Oui/Non)
  test "ac1634 returns nil when no setting exists" do
    assert_nil @survey.ac1634
  end

  test "ac1634 returns setting value" do
    Setting.create!(organization: @organization, key: "records_minutes_of_assembly", category: "kyc_procedures", value: "Non")
    assert_equal "Non", @survey.ac1634
  end

  # C39 — aC1635: Records BO identity documents for LE? (enum Oui/Non)
  test "ac1635 returns nil when no setting exists" do
    assert_nil @survey.ac1635
  end

  test "ac1635 returns setting value" do
    Setting.create!(organization: @organization, key: "records_bo_identity_documents", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1635
  end

  # C40 — aC1636: Records other LE/construction data? (enum Oui/Non)
  # Fixture already has records_other_le_data: "Oui" for org :one
  test "ac1636 returns setting value from fixture" do
    assert_equal "Oui", @survey.ac1636
  end

  # C41 — aC1637: Specify other LE data (free text, conditional on aC1636)
  test "ac1637 returns nil when ac1636 is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.ac1637
  end

  test "ac1637 returns setting value when ac1636 is Oui from fixture" do
    # Fixture: records_other_le_data = "Oui", other_le_data_details = "Numéro RCI, ..."
    assert_match(/Numéro RCI/, @survey.ac1637)
  end

  # C42 — aC1608: Former client data accessible to AMSF on request? (enum Oui/Non)
  test "ac1608 returns nil when no setting exists" do
    assert_nil @survey.ac1608
  end

  test "ac1608 returns setting value" do
    Setting.create!(organization: @organization, key: "former_client_data_accessible_to_amsf", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1608
  end

  # C43 — aC1635A: All documents systematically retained? (enum Oui/Non)
  test "ac1635a returns nil when no setting exists" do
    assert_nil @survey.ac1635a
  end

  test "ac1635a returns setting value" do
    Setting.create!(organization: @organization, key: "documents_systematically_retained", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1635a
  end

  # C44 — aC1638A: Retains summary documents? (enum Oui/Non)
  test "ac1638a returns nil when no setting exists" do
    assert_nil @survey.ac1638a
  end

  test "ac1638a returns setting value" do
    Setting.create!(organization: @organization, key: "retains_summary_documents", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1638a
  end

  # C45 — aC1639A: Info stored in database? (enum Oui/Non, conditional on aC1638A)
  test "ac1639a returns nil when ac1638a is not Oui" do
    assert_nil @survey.ac1639a
  end

  test "ac1639a returns setting value when ac1638a is Oui" do
    Setting.create!(organization: @organization, key: "retains_summary_documents", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "info_stored_in_database", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1639a
  end

  # C46 — aC1641A: Uses CDD tools? (enum Oui/Non)
  test "ac1641a returns nil when no setting exists" do
    assert_nil @survey.ac1641a
  end

  test "ac1641a returns setting value" do
    Setting.create!(organization: @organization, key: "uses_cdd_tools", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1641a
  end

  # C47 — aC1640A: Which CDD tools? (free text, conditional on aC1641A)
  test "ac1640a returns nil when ac1641a is not Oui" do
    assert_nil @survey.ac1640a
  end

  test "ac1640a returns setting value when ac1641a is Oui" do
    Setting.create!(organization: @organization, key: "uses_cdd_tools", category: "kyc_procedures", value: "Oui")
    # Fixture already has cdd_tools_description for org :one
    assert_match(/immobilière/, @survey.ac1640a)
  end

  # C48 — aC1642A: CDD tool results systematically stored? (enum Oui/Non, conditional on aC1641A)
  test "ac1642a returns nil when ac1641a is not Oui" do
    assert_nil @survey.ac1642a
  end

  test "ac1642a returns setting value when ac1641a is Oui" do
    Setting.create!(organization: @organization, key: "uses_cdd_tools", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "cdd_results_systematically_stored", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1642a
  end

  # C49 — aC1609: Risk-based approach for CDD? (enum Oui/Non)
  test "ac1609 returns nil when no setting exists" do
    assert_nil @survey.ac1609
  end

  test "ac1609 returns setting value" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1609
  end

  # C50 — aC1610: Policies distinguish CDD levels? (enum Oui/Non, conditional on aC1609)
  test "ac1610 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1610
  end

  test "ac1610 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "policies_distinguish_cdd_levels", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1610
  end

  # C51 — aC1611: Total unique active clients (integerItemType, conditional on aC1609)
  test "ac1611 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1611
  end

  test "ac1611 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "total_unique_active_clients_cdd", category: "kyc_procedures", value: "150")
    assert_equal "150", @survey.ac1611
  end

  # C52 — aC1612A: Implemented simplified DD? (enum Oui/Non, conditional on aC1609)
  test "ac1612a returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1612a
  end

  test "ac1612a returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "implemented_simplified_dd", category: "kyc_procedures", value: "Non")
    assert_equal "Non", @survey.ac1612a
  end

  # C53 — aC1612: Total clients with simplified DD (integerItemType, conditional on aC1612A)
  test "ac1612 returns nil when ac1612a is not Oui" do
    assert_nil @survey.ac1612
  end

  test "ac1612 returns setting value when ac1612a is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "implemented_simplified_dd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "simplified_dd_client_count", category: "kyc_procedures", value: "5")
    assert_equal "5", @survey.ac1612
  end

  # C54 — aC1614: Identifies/verifies clients using reliable independent info? (enum Oui/Non)
  test "ac1614 returns nil when no setting exists" do
    assert_nil @survey.ac1614
  end

  test "ac1614 returns setting value" do
    Setting.create!(organization: @organization, key: "verifies_clients_with_reliable_info", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1614
  end

  # C55 — aC1615: CDD policies include client acceptance/identification procedures? (enum Oui/Non)
  test "ac1615 returns nil when no setting exists" do
    assert_nil @survey.ac1615
  end

  test "ac1615 returns setting value" do
    Setting.create!(organization: @organization, key: "cdd_policies_include_acceptance_procedures", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1615
  end

  # C56 — aC1622F: Uses third parties for CDD? (enum Oui/Non)
  test "ac1622f returns nil when no setting exists" do
    assert_nil @survey.ac1622f
  end

  test "ac1622f returns setting value" do
    Setting.create!(organization: @organization, key: "uses_third_parties_for_cdd", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1622f
  end

  # C57 — aC1622A: Difficulties receiving CDD info from third parties? (conditional on aC1622F)
  test "ac1622a returns nil when ac1622f is not Oui" do
    assert_nil @survey.ac1622a
  end

  test "ac1622a returns setting value when ac1622f is Oui" do
    Setting.create!(organization: @organization, key: "uses_third_parties_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "difficulties_receiving_cdd_from_third_parties", category: "kyc_procedures", value: "Non")
    assert_equal "Non", @survey.ac1622a
  end

  # C58 — aC1622B: Main reason for difficulties (free text, conditional on aC1622A)
  test "ac1622b returns nil when ac1622a is not Oui" do
    assert_nil @survey.ac1622b
  end

  test "ac1622b returns setting value when ac1622a is Oui" do
    Setting.create!(organization: @organization, key: "uses_third_parties_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "difficulties_receiving_cdd_from_third_parties", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "cdd_difficulties_reason", category: "kyc_procedures", value: "Legal restrictions in jurisdiction")
    assert_equal "Legal restrictions in jurisdiction", @survey.ac1622b
  end

  # C59 — aC1620: Enhanced identification for high-risk clients? (conditional on aC1609)
  test "ac1620 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1620
  end

  test "ac1620 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "enhanced_id_for_high_risk_clients", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1620
  end

  # C60 — aC1617: Examines source of wealth before relationship? (enum Oui/Non)
  test "ac1617 returns nil when no setting exists" do
    assert_nil @survey.ac1617
  end

  test "ac1617 returns setting value" do
    Setting.create!(organization: @organization, key: "examines_source_of_wealth", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1617
  end

  # C61 — aC1616B: Frequency of high-risk purchase/sale client review (frequency enum, conditional on aC1609)
  test "ac1616b returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1616b
  end

  test "ac1616b returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "high_risk_purchase_sale_review_frequency", category: "kyc_procedures", value: "< Annuel")
    assert_equal "< Annuel", @survey.ac1616b
  end

  # C62 — aC1616A: Frequency of high-risk rental client review (frequency enum, conditional on aC1609)
  test "ac1616a returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1616a
  end

  test "ac1616a returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "high_risk_rental_review_frequency", category: "kyc_procedures", value: "< Annuel")
    assert_equal "< Annuel", @survey.ac1616a
  end

  # C63 — aC1618: Other measures for high-risk clients? (conditional on aC1609)
  test "ac1618 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1618
  end

  test "ac1618 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "other_measures_for_high_risk_clients", category: "kyc_procedures", value: "Oui")
    assert_equal "Oui", @survey.ac1618
  end

  # C64 — aC1619: Specify other measures (free text, conditional on aC1618)
  test "ac1619 returns nil when ac1618 is not Oui" do
    assert_nil @survey.ac1619
  end

  test "ac1619 returns setting value when ac1618 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "other_measures_for_high_risk_clients", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "other_high_risk_measures_description", category: "kyc_procedures", value: "Enhanced monitoring")
    assert_equal "Enhanced monitoring", @survey.ac1619
  end

  # C65 — aC1616C: Clients use cryptocurrency for real estate? (enum Oui/Non)
  test "ac1616c returns nil when no setting exists" do
    assert_nil @survey.ac1616c
  end

  test "ac1616c returns setting value" do
    Setting.create!(organization: @organization, key: "clients_use_crypto_for_real_estate", category: "kyc_procedures", value: "Non")
    assert_equal "Non", @survey.ac1616c
  end

  # C66 — aC1621: How entity verifies virtual asset BOs (free text, conditional on aC1616C)
  test "ac1621 returns nil when ac1616c is not Oui" do
    assert_nil @survey.ac1621
  end

  test "ac1621 returns setting value when ac1616c is Oui" do
    Setting.create!(organization: @organization, key: "clients_use_crypto_for_real_estate", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "virtual_asset_bo_verification_method", category: "kyc_procedures", value: "Blockchain analysis tools")
    assert_equal "Blockchain analysis tools", @survey.ac1621
  end

  # ============================================================
  # Section 1.7 — EDD (C67–C69)
  # ============================================================

  # C67 — aC1701: Total EDD clients at onboarding (integerItemType, conditional on aC1609)
  test "ac1701 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1701
  end

  test "ac1701 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "edd_clients_at_onboarding_count", category: "controls", value: "8")
    assert_equal "8", @survey.ac1701
  end

  # C68 — aC1702: Total EDD clients during ongoing relationship (integerItemType, conditional on aC1609)
  test "ac1702 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1702
  end

  test "ac1702 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "edd_clients_ongoing_count", category: "controls", value: "12")
    assert_equal "12", @survey.ac1702
  end

  # C69 — aC1703: Percentage of EDD clients (pureItemType 0-100, conditional on aC1609)
  test "ac1703 returns nil when ac1609 is not Oui" do
    assert_nil @survey.ac1703
  end

  test "ac1703 returns setting value when ac1609 is Oui" do
    Setting.create!(organization: @organization, key: "risk_based_approach_for_cdd", category: "kyc_procedures", value: "Oui")
    Setting.create!(organization: @organization, key: "edd_clients_percentage", category: "controls", value: "15.5")
    assert_equal "15.5", @survey.ac1703
  end

  # ============================================================
  # Section 1.8 — Risk Assessments (C70–C78)
  # ============================================================

  # C70 — aB1801B: Applies risk ratings to clients? (enum Oui/Non)
  test "ab1801b returns nil when no setting exists" do
    assert_nil @survey.ab1801b
  end

  test "ab1801b returns setting value" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ab1801b
  end

  # C71 — aC1801: How many risk levels? (integerItemType, conditional on aB1801B)
  test "ac1801 returns nil when ab1801b is not Oui" do
    assert_nil @survey.ac1801
  end

  test "ac1801 returns setting value when ab1801b is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "number_of_risk_levels", category: "controls", value: "3")
    assert_equal "3", @survey.ac1801
  end

  # C72 — aC1802: Total high-risk clients (integerItemType, conditional on aB1801B)
  test "ac1802 returns nil when ab1801b is not Oui" do
    assert_nil @survey.ac1802
  end

  test "ac1802 returns setting value when ab1801b is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "high_risk_clients_count", category: "controls", value: "7")
    assert_equal "7", @survey.ac1802
  end

  # C73 — aC1806: High-risk considerations include all required factors? (conditional on aB1801B)
  # Fixture has risk_assessment_includes_all_factors: "Oui" for org :one
  test "ac1806 returns nil when ab1801b is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.ac1806
  end

  test "ac1806 returns setting value when ab1801b is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac1806
  end

  # C74 — aC1807: Specify which elements not considered (conditional on aC1806 == "Non")
  # Fixture has risk_factors_not_considered for org :one, but aC1806 fixture is "Oui" so it returns nil
  test "ac1807 returns nil when ac1806 is not Non" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    # aC1806 fixture = "Oui", so ac1807 should be nil
    assert_nil @survey.ac1807
  end

  test "ac1807 returns setting value when ac1806 is Non" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    Setting.find_by(organization: @organization, key: "risk_assessment_includes_all_factors").update!(value: "Non")
    assert_match(/immobilières/, @survey.ac1807)
  end

  # C75 — aC1811: Uses sensitive countries list? (conditional on aB1801B)
  # Fixture has uses_sensitive_countries_list: "Oui" for org :one
  test "ac1811 returns nil when ab1801b is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.ac1811
  end

  test "ac1811 returns setting value when ab1801b is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac1811
  end

  # C76 — aC1812: Uses sensitive activities list? (conditional on aB1801B)
  # Fixture has uses_sensitive_activities_list: "Oui" for org :one
  test "ac1812 returns nil when ab1801b is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.ac1812
  end

  test "ac1812 returns setting value when ab1801b is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac1812
  end

  # C77 — aC1813: Which high-risk client activities? (free text, conditional on aC1812)
  # Fixture has high_risk_client_activities for org :one, and uses_sensitive_activities_list: "Oui"
  test "ac1813 returns nil when ac1812 is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.ac1813
  end

  test "ac1813 returns setting value when ac1812 is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    # Fixture: uses_sensitive_activities_list = "Oui", high_risk_client_activities = "Investissement locatif..."
    assert_match(/Investissement/, @survey.ac1813)
  end

  # C78 — aC1814W: Examines ML and TF risks separately? (conditional on aB1801B)
  # Fixture has separates_ml_and_tf_risks: "Oui" for org :one
  test "ac1814w returns nil when ab1801b is not Oui" do
    survey = Survey.new(organization: organizations(:company), year: @year)
    assert_nil survey.ac1814w
  end

  test "ac1814w returns setting value when ab1801b is Oui" do
    Setting.create!(organization: @organization, key: "applies_risk_ratings_to_clients", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac1814w
  end

  # ============================================================
  # Section 1.9 — Audit (C79)
  # ============================================================

  # C79 — aC1904: Last AMSF/SICCFIN audit date (7-value enum)
  test "ac1904 returns nil when no setting exists" do
    assert_nil @survey.ac1904
  end

  test "ac1904 returns setting value" do
    Setting.create!(organization: @organization, key: "last_amsf_audit_recency", category: "controls", value: "Entre un et deux ans")
    assert_equal "Entre un et deux ans", @survey.ac1904
  end

  # ============================================================
  # Section 1.10 — Record Keeping (C80–C84)
  # ============================================================

  # C80 — aC11101: Retains transaction info for 5+ years? (enum Oui/Non)
  test "ac11101 returns nil when no setting exists" do
    assert_nil @survey.ac11101
  end

  test "ac11101 returns setting value" do
    Setting.create!(organization: @organization, key: "retains_transaction_info_5_years", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11101
  end

  # C81 — aC11102: Retains CDD correspondence for 5+ years? (enum Oui/Non)
  test "ac11102 returns nil when no setting exists" do
    assert_nil @survey.ac11102
  end

  test "ac11102 returns setting value" do
    Setting.create!(organization: @organization, key: "retains_cdd_correspondence_5_years", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11102
  end

  # C82 — aC11103: Info stored securely? (conditional on aC11101)
  test "ac11103 returns nil when ac11101 is not Oui" do
    assert_nil @survey.ac11103
  end

  test "ac11103 returns setting value when ac11101 is Oui" do
    Setting.create!(organization: @organization, key: "retains_transaction_info_5_years", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "info_stored_securely", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11103
  end

  # C83 — aC11104: Info available to authorities on request? (conditional on aC11101)
  test "ac11104 returns nil when ac11101 is not Oui" do
    assert_nil @survey.ac11104
  end

  test "ac11104 returns setting value when ac11101 is Oui" do
    Setting.create!(organization: @organization, key: "retains_transaction_info_5_years", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "info_available_to_authorities", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11104
  end

  # C84 — aC11105: Has data backup and recovery plan? (conditional on aC11101)
  test "ac11105 returns nil when ac11101 is not Oui" do
    assert_nil @survey.ac11105
  end

  test "ac11105 returns setting value when ac11101 is Oui" do
    Setting.create!(organization: @organization, key: "retains_transaction_info_5_years", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "has_data_backup_recovery_plan", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11105
  end

  # ============================================================
  # Section 1.11 — TFS (C85–C89)
  # ============================================================

  # C85 — aC11201: Policies cover TFS screening? (enum Oui/Non)
  test "ac11201 returns nil when no setting exists" do
    assert_nil @survey.ac11201
  end

  test "ac11201 returns setting value" do
    Setting.create!(organization: @organization, key: "policies_cover_tfs_screening", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11201
  end

  # C86 — aC1125A: Consults national asset freeze list? (enum Oui/Non)
  test "ac1125a returns nil when no setting exists" do
    assert_nil @survey.ac1125a
  end

  test "ac1125a returns setting value" do
    Setting.create!(organization: @organization, key: "consults_national_asset_freeze_list", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac1125a
  end

  # C87 — aC12333: Identified TF/WMD proliferation financing? (enum Oui/Non)
  test "ac12333 returns nil when no setting exists" do
    assert_nil @survey.ac12333
  end

  test "ac12333 returns setting value" do
    Setting.create!(organization: @organization, key: "identified_tf_or_wmd_financing", category: "controls", value: "Non")
    assert_equal "Non", @survey.ac12333
  end

  # C88 — aC12236: Total TF declarations to DBT (integerItemType, conditional on aC12333)
  test "ac12236 returns nil when ac12333 is not Oui" do
    assert_nil @survey.ac12236
  end

  test "ac12236 returns setting value when ac12333 is Oui" do
    Setting.create!(organization: @organization, key: "identified_tf_or_wmd_financing", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "tf_declarations_to_dbt_count", category: "controls", value: "0")
    assert_equal "0", @survey.ac12236
  end

  # C89 — aC12237: Total WMD proliferation declarations to DBT (integerItemType, conditional on aC12333)
  test "ac12237 returns nil when ac12333 is not Oui" do
    assert_nil @survey.ac12237
  end

  test "ac12237 returns setting value when ac12333 is Oui" do
    Setting.create!(organization: @organization, key: "identified_tf_or_wmd_financing", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "wmd_proliferation_declarations_to_dbt_count", category: "controls", value: "0")
    assert_equal "0", @survey.ac12237
  end

  # ============================================================
  # Section 1.12 — PEPs (C90–C96)
  # ============================================================

  # C90 — aC11301: Takes measures to determine PEP status? (enum Oui/Non)
  test "ac11301 returns nil when no setting exists" do
    assert_nil @survey.ac11301
  end

  test "ac11301 returns setting value" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11301
  end

  # C91 — aC11302: Which measures for PEP determination? (free text, conditional on aC11301)
  test "ac11302 returns nil when ac11301 is not Oui" do
    assert_nil @survey.ac11302
  end

  test "ac11302 returns setting value when ac11301 is Oui" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "pep_determination_measures", category: "controls", value: "Database screening")
    assert_equal "Database screening", @survey.ac11302
  end

  # C92 — aC11303: Additional PEP procedures? (free text, conditional on aC11301)
  test "ac11303 returns nil when ac11301 is not Oui" do
    assert_nil @survey.ac11303
  end

  test "ac11303 returns setting value when ac11301 is Oui" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "additional_pep_procedures", category: "controls", value: "Enhanced monitoring and senior approval")
    assert_equal "Enhanced monitoring and senior approval", @survey.ac11303
  end

  # C93 — aC11304: PEP screening for new clients? (conditional on aC11301)
  test "ac11304 returns nil when ac11301 is not Oui" do
    assert_nil @survey.ac11304
  end

  test "ac11304 returns setting value when ac11301 is Oui" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "pep_screening_for_new_clients", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11304
  end

  # C94 — aC11305: Continuous PEP screening? (conditional on aC11301)
  test "ac11305 returns nil when ac11301 is not Oui" do
    assert_nil @survey.ac11305
  end

  test "ac11305 returns setting value when ac11301 is Oui" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "continuous_pep_screening", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11305
  end

  # C95 — aC11306: Enhanced PEP surveillance? (conditional on aC11301)
  test "ac11306 returns nil when ac11301 is not Oui" do
    assert_nil @survey.ac11306
  end

  test "ac11306 returns setting value when ac11301 is Oui" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "enhanced_pep_surveillance", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11306
  end

  # C96 — aC11307: All PEP relationships high-risk? (conditional on aC11301)
  test "ac11307 returns nil when ac11301 is not Oui" do
    assert_nil @survey.ac11307
  end

  test "ac11307 returns setting value when ac11301 is Oui" do
    Setting.create!(organization: @organization, key: "takes_measures_to_determine_pep_status", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "all_pep_relationships_high_risk", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11307
  end

  # ============================================================
  # Section 1.13 — Cash Transactions (C97–C99)
  # ============================================================

  # C97 — aC11401: Entity performs cash operations? (enum Oui/Non)
  test "ac11401 returns nil when no setting exists" do
    assert_nil @survey.ac11401
  end

  test "ac11401 returns setting value" do
    Setting.create!(organization: @organization, key: "performs_cash_operations_with_clients", category: "controls", value: "Non")
    assert_equal "Non", @survey.ac11401
  end

  # C98 — aC11402: Applies specific AML controls for cash? (conditional on aC11401)
  test "ac11402 returns nil when ac11401 is not Oui" do
    assert_nil @survey.ac11402
  end

  test "ac11402 returns setting value when ac11401 is Oui" do
    Setting.create!(organization: @organization, key: "performs_cash_operations_with_clients", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "applies_aml_controls_for_cash", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11402
  end

  # C99 — aC11403: Describe cash-specific AML controls (free text, conditional on aC11402)
  test "ac11403 returns nil when ac11402 is not Oui" do
    assert_nil @survey.ac11403
  end

  test "ac11403 returns setting value when ac11402 is Oui" do
    Setting.create!(organization: @organization, key: "performs_cash_operations_with_clients", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "applies_aml_controls_for_cash", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "cash_aml_controls_description", category: "controls", value: "Cash register, receipts, reporting above 10k EUR")
    assert_equal "Cash register, receipts, reporting above 10k EUR", @survey.ac11403
  end

  # ============================================================
  # Section 1.14 — STR (C100–C103)
  # ============================================================

  # C100 — aC11501B: Filed STRs/SARs with FIU? (enum Oui/Non)
  test "ac11501b returns nil when no setting exists" do
    assert_nil @survey.ac11501b
  end

  test "ac11501b returns setting value" do
    Setting.create!(organization: @organization, key: "filed_strs_with_fiu", category: "controls", value: "Non")
    assert_equal "Non", @survey.ac11501b
  end

  # C101 — aC11502: Total TF-related STRs (integerItemType, conditional on aC11501B)
  test "ac11502 returns nil when ac11501b is not Oui" do
    assert_nil @survey.ac11502
  end

  test "ac11502 returns setting value when ac11501b is Oui" do
    Setting.create!(organization: @organization, key: "filed_strs_with_fiu", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "tf_related_strs_count", category: "controls", value: "0")
    assert_equal "0", @survey.ac11502
  end

  # C102 — aC11504: Total ML-related STRs (integerItemType, conditional on aC11501B)
  test "ac11504 returns nil when ac11501b is not Oui" do
    assert_nil @survey.ac11504
  end

  test "ac11504 returns setting value when ac11501b is Oui" do
    Setting.create!(organization: @organization, key: "filed_strs_with_fiu", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "ml_related_strs_count", category: "controls", value: "2")
    assert_equal "2", @survey.ac11504
  end

  # C103 — aC11508: Taken measures to strengthen internal AML controls? (enum Oui/Non)
  test "ac11508 returns nil when no setting exists" do
    assert_nil @survey.ac11508
  end

  test "ac11508 returns setting value" do
    Setting.create!(organization: @organization, key: "strengthened_internal_aml_controls", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac11508
  end

  # ============================================================
  # Section 1.15 — Comments & Feedback (C104–C105)
  # ============================================================

  # C104 — aC116A: Has comments on controls section? (enum Oui/Non)
  test "ac116a returns nil when no setting exists" do
    assert_nil @survey.ac116a
  end

  test "ac116a returns setting value" do
    Setting.create!(organization: @organization, key: "has_controls_section_comments", category: "controls", value: "Oui")
    assert_equal "Oui", @survey.ac116a
  end

  # C105 — aC11601: Controls section comments (free text, conditional on aC116A)
  test "ac11601 returns nil when ac116a is not Oui" do
    assert_nil @survey.ac11601
  end

  test "ac11601 returns setting value when ac116a is Oui" do
    Setting.create!(organization: @organization, key: "has_controls_section_comments", category: "controls", value: "Oui")
    Setting.create!(organization: @organization, key: "controls_section_comments", category: "controls", value: "No additional comments")
    assert_equal "No additional comments", @survey.ac11601
  end

  # ============================================================
  # Signatories (S1–S3)
  # ============================================================

  # S1 — aS1: Signatory attestation
  test "as1 returns nil when no setting exists" do
    assert_nil @survey.as1
  end

  test "as1 returns setting value" do
    Setting.create!(organization: @organization, key: "signatory_attestation", category: "entity_info", value: "Jean Dupont, Directeur Général")
    assert_equal "Jean Dupont, Directeur Général", @survey.as1
  end

  # S2 — aS2: Authorized representative attestation
  test "as2 returns nil when no setting exists" do
    assert_nil @survey.as2
  end

  test "as2 returns setting value" do
    Setting.create!(organization: @organization, key: "authorized_representative_attestation", category: "entity_info", value: "Marie Martin, Responsable Conformité")
    assert_equal "Marie Martin, Responsable Conformité", @survey.as2
  end

  # S3 — aINCOMPLETE: Incomplete submission reason
  test "aincomplete returns nil when no setting exists" do
    assert_nil @survey.aincomplete
  end

  test "aincomplete returns setting value" do
    Setting.create!(organization: @organization, key: "incomplete_submission_reason", category: "entity_info", value: "Complet")
    assert_equal "Complet", @survey.aincomplete
  end

  # Coverage — ensure all 323 questionnaire fields have a method implementation
  test "Survey implements all questionnaire fields" do
    questionnaire = AmsfSurvey.questionnaire(industry: :real_estate, year: 2025)
    survey = Survey.new(organization: @organization, year: 2025)

    missing = questionnaire.questions.map { |q| q.id.to_s.downcase.to_sym }.reject do |field_id|
      survey.respond_to?(field_id, true)
    end

    assert missing.empty?, "Survey is missing implementations for: #{missing.join(", ")}"
  end
end
