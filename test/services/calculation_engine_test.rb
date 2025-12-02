# frozen_string_literal: true

require "test_helper"

class CalculationEngineTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @user = users(:one)
    set_current_context(user: @user, organization: @organization)

    # Create a submission for the current year
    @submission = Submission.create!(
      organization: @organization,
      year: Date.current.year
    )
    @engine = CalculationEngine.new(@submission)
  end

  # === Initialization ===

  test "initializes with submission" do
    engine = CalculationEngine.new(@submission)
    assert_not_nil engine
  end

  test "calculates all values" do
    results = @engine.calculate_all
    assert_kind_of Hash, results
    assert results.keys.any?, "Expected results to have keys"
  end

  # === Client Statistics ===

  test "calculates total client count" do
    results = @engine.calculate_all
    # Count active, non-discarded clients for organization one
    expected_count = @organization.clients.kept.count
    assert_equal expected_count, results["a1101"].to_i
  end

  test "calculates natural persons count" do
    results = @engine.calculate_all
    expected = @organization.clients.kept.natural_persons.count
    assert_equal expected, results["a1102"].to_i
  end

  test "calculates legal entities count" do
    results = @engine.calculate_all
    expected = @organization.clients.kept.legal_entities.count
    assert_equal expected, results["a11502B"].to_i
  end

  test "calculates trusts count" do
    results = @engine.calculate_all
    expected = @organization.clients.kept.trusts.count
    assert_equal expected, results["a11802B"].to_i
  end

  test "calculates PEP clients count" do
    results = @engine.calculate_all
    expected = @organization.clients.kept.peps.count
    assert_equal expected, results["a1301"].to_i
  end

  test "calculates high risk clients count" do
    results = @engine.calculate_all
    expected = @organization.clients.kept.high_risk.count
    assert_equal expected, results["a1401"].to_i
  end

  # === Client Nationality Breakdowns ===

  test "calculates clients by nationality" do
    results = @engine.calculate_all

    # Monaco nationals
    mc_count = @organization.clients.kept.where(nationality: "MC").count
    assert_equal mc_count, results["a1103_MC"].to_i if mc_count > 0

    # French nationals
    fr_count = @organization.clients.kept.where(nationality: "FR").count
    assert_equal fr_count, results["a1103_FR"].to_i if fr_count > 0
  end

  # === Transaction Statistics ===

  test "calculates total transaction count" do
    results = @engine.calculate_all
    # Only transactions for the submission year
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).count
    assert_equal expected, results["a2101B"].to_i
  end

  test "calculates purchase count" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).purchases.count
    assert_equal expected, results["a2102"].to_i
  end

  test "calculates sale count" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).sales.count
    assert_equal expected, results["a2103"].to_i
  end

  test "calculates rental count" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).rentals.count
    assert_equal expected, results["a2104"].to_i
  end

  test "calculates total transaction value" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).sum(:transaction_value)
    assert_equal expected, BigDecimal(results["a2104B"].to_s)
  end

  test "calculates purchase value" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).purchases.sum(:transaction_value)
    assert_equal expected, BigDecimal(results["a2105"].to_s)
  end

  test "calculates sale value" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).sales.sum(:transaction_value)
    assert_equal expected, BigDecimal(results["a2106"].to_s)
  end

  test "calculates rental value" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year).rentals.sum(:transaction_value)
    assert_equal expected, BigDecimal(results["a2107"].to_s)
  end

  # === Payment Method Statistics ===

  test "calculates cash transaction count" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year)
                           .where(payment_method: %w[CASH MIXED]).count
    assert_equal expected, results["a2201"].to_i
  end

  test "calculates total cash amount" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year)
                           .where(payment_method: %w[CASH MIXED])
                           .sum(:cash_amount)
    assert_equal expected, BigDecimal(results["a2202"].to_s)
  end

  test "calculates crypto transaction count" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year)
                           .where(payment_method: "CRYPTO").count
    assert_equal expected, results["a2301"].to_i
  end

  test "calculates crypto transaction value" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.transactions.kept.for_year(year)
                           .where(payment_method: "CRYPTO")
                           .sum(:transaction_value)
    assert_equal expected, BigDecimal(results["a2302"].to_s)
  end

  # === PEP Transaction Statistics ===

  test "calculates transactions with PEP clients" do
    results = @engine.calculate_all
    year = @submission.year
    pep_client_ids = @organization.clients.kept.peps.pluck(:id)
    expected = @organization.transactions.kept.for_year(year)
                           .where(client_id: pep_client_ids).count
    assert_equal expected, results["a2401"].to_i
  end

  # === STR Statistics ===

  test "calculates STR count for year" do
    results = @engine.calculate_all
    year = @submission.year
    expected = @organization.str_reports.kept
                           .where(report_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
                           .count
    assert_equal expected, results["a3101"].to_i
  end

  # === Beneficial Owner Statistics ===

  test "calculates total beneficial owners count" do
    results = @engine.calculate_all
    expected = @organization.clients.kept.legal_entities
                           .joins(:beneficial_owners)
                           .merge(BeneficialOwner.all)
                           .count
    expected += @organization.clients.kept.trusts
                            .joins(:beneficial_owners)
                            .merge(BeneficialOwner.all)
                            .count
    assert_equal expected, results["a1501"].to_i
  end

  test "calculates PEP beneficial owners count" do
    results = @engine.calculate_all
    expected = BeneficialOwner.joins(:client)
                             .where(clients: { organization_id: @organization.id })
                             .where(is_pep: true)
                             .count
    assert_equal expected, results["a1502"].to_i
  end

  # === Edge Cases ===

  test "handles organization with no clients" do
    empty_org = organizations(:two)
    # Delete transactions first (they reference clients), then clients
    empty_org.transactions.each(&:discard)
    empty_org.clients.each(&:discard)

    submission = Submission.create!(organization: empty_org, year: 2040)
    engine = CalculationEngine.new(submission)

    results = engine.calculate_all
    assert_equal 0, results["a1101"].to_i
    assert_equal 0, results["a2101B"].to_i
  end

  test "handles submission for past year" do
    # Use a year that doesn't conflict with fixtures
    past_submission = Submission.create!(
      organization: @organization,
      year: 2035
    )
    engine = CalculationEngine.new(past_submission)

    results = engine.calculate_all
    # Should only count transactions from that year
    assert_kind_of Hash, results
  end

  test "excludes discarded clients from calculations" do
    # Ensure we have a discarded client
    discarded = clients(:discarded_client)
    assert discarded.discarded?

    results = @engine.calculate_all
    total_clients = results["a1101"].to_i

    # Count should not include discarded
    assert_equal @organization.clients.kept.count, total_clients
  end

  test "excludes discarded transactions from calculations" do
    # Ensure we have a discarded transaction
    discarded = transactions(:discarded_transaction)
    assert discarded.discarded?

    results = @engine.calculate_all
    year = @submission.year
    total_txns = results["a2101B"].to_i

    # Count should not include discarded
    expected = @organization.transactions.kept.for_year(year).count
    assert_equal expected, total_txns
  end

  # === Populate Submission Values ===

  test "populate_submission_values creates SubmissionValue records" do
    initial_count = @submission.submission_values.count
    @engine.populate_submission_values!

    # Should have created multiple records
    assert @submission.submission_values.count > initial_count,
           "Expected submission values to be created"

    # Verify some key values were created
    assert @submission.submission_values.exists?(element_name: "a1101")
    assert @submission.submission_values.exists?(element_name: "a2101B")
  end

  test "populate_submission_values sets source to calculated" do
    @engine.populate_submission_values!

    value = @submission.submission_values.find_by(element_name: "a1101")
    assert_equal "calculated", value.source
  end

  test "populate_submission_values is idempotent" do
    @engine.populate_submission_values!
    initial_count = @submission.submission_values.count

    # Running again should not create duplicates
    @engine.populate_submission_values!
    assert_equal initial_count, @submission.submission_values.count
  end
end
