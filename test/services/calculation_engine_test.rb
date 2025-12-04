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

  # === Managed Property Statistics (US1 - AMSF Data Capture) ===

  test "calculates managed property statistics" do
    # Use the submission created in setup (for current year)
    results = @engine.managed_property_statistics

    # Should return hash with management statistics
    assert_kind_of Hash, results
    assert results.key?("a1802TOLA"), "Expected tenant count element a1802TOLA"
  end

  test "calculates active property count" do
    results = @engine.managed_property_statistics
    year = @submission.year

    # Count properties active in submission year for org one
    expected = @organization.managed_properties.active_in_year(year).count
    assert_equal expected, results["aACTIVEPS"].to_i
  end

  test "calculates tenant by type breakdown" do
    results = @engine.managed_property_statistics

    # Should have natural person and legal entity tenant counts
    assert results.key?("a1802TOLA_NP") || results.key?("a1802TOLA_LE"),
           "Expected tenant type breakdown elements"
  end

  test "calculates PEP tenant count" do
    results = @engine.managed_property_statistics
    year = @submission.year

    # Count PEP tenants in active properties
    expected = @organization.managed_properties
                            .active_in_year(year)
                            .where(tenant_is_pep: true).count
    assert_equal expected, results["a1802PEP"].to_i
  end

  # === Training Statistics (US1 - AMSF Data Capture) ===

  test "calculates training statistics" do
    results = @engine.training_statistics

    # Should return hash with training statistics
    assert_kind_of Hash, results
    assert results.key?("a3201"), "Expected training conducted element a3201"
  end

  test "calculates training conducted flag" do
    results = @engine.training_statistics
    year = @submission.year

    # a3201 is Oui/Non flag - did organization conduct training?
    trainings_exist = @organization.trainings.for_year(year).exists?
    expected = trainings_exist ? "Oui" : "Non"
    assert_equal expected, results["a3201"]
  end

  test "calculates staff trained count" do
    results = @engine.training_statistics
    year = @submission.year

    # a3202 is total staff trained (sum of staff_count from all trainings)
    expected = @organization.trainings.for_year(year).sum(:staff_count)
    assert_equal expected, results["a3202"].to_i
  end

  test "calculates training session count" do
    results = @engine.training_statistics
    year = @submission.year

    # a3203 is number of training sessions
    expected = @organization.trainings.for_year(year).count
    assert_equal expected, results["a3203"].to_i
  end

  test "calculates training hours" do
    results = @engine.training_statistics
    year = @submission.year

    # a3303 is total training hours
    expected = @organization.trainings.for_year(year).sum(:duration_hours)
    assert_equal expected, BigDecimal(results["a3303"].to_s)
  end

  # === Revenue Statistics (US1 - AMSF Data Capture) ===

  test "calculates revenue statistics" do
    results = @engine.revenue_statistics

    # Should return hash with revenue elements
    assert_kind_of Hash, results
    assert results.key?("a381"), "Expected total revenue element a381"
  end

  test "calculates sales commission revenue" do
    results = @engine.revenue_statistics
    year = @submission.year

    # a3802 is sales commission revenue
    # Calculated from sales transactions' commission_amount
    year_sales = @organization.transactions.kept.for_year(year).sales
    expected = year_sales.sum(:commission_amount)
    assert_equal expected, BigDecimal(results["a3802"].to_s)
  end

  test "calculates rental commission revenue" do
    results = @engine.revenue_statistics
    year = @submission.year

    # a3803 is rental commission revenue
    year_rentals = @organization.transactions.kept.for_year(year).rentals
    expected = year_rentals.sum(:commission_amount)
    assert_equal expected, BigDecimal(results["a3803"].to_s)
  end

  test "calculates property management revenue" do
    results = @engine.revenue_statistics
    year = @submission.year

    # a3804 is property management revenue (calculated from managed properties)
    expected = @organization.managed_properties.active_in_year(year).sum do |prop|
      prop.annual_revenue(year)
    end
    assert_equal expected, BigDecimal(results["a3804"].to_s)
  end

  test "calculates total revenue" do
    results = @engine.revenue_statistics

    # a381 is total of a3802 + a3803 + a3804
    sales_rev = BigDecimal(results["a3802"].to_s)
    rental_rev = BigDecimal(results["a3803"].to_s)
    mgmt_rev = BigDecimal(results["a3804"].to_s)
    expected = sales_rev + rental_rev + mgmt_rev
    assert_equal expected, BigDecimal(results["a381"].to_s)
  end

  # === Extended Client Statistics (US1 - AMSF Data Capture) ===

  test "calculates extended client statistics" do
    results = @engine.extended_client_statistics

    # Should return hash with extended client elements
    assert_kind_of Hash, results
    assert results.key?("a1203") || results.key?("a1203D"),
           "Expected due diligence level elements"
  end

  test "calculates clients by due diligence level" do
    results = @engine.extended_client_statistics

    # a1203 is count of SIMPLIFIED due diligence clients
    simplified_count = @organization.clients.kept
                                    .where(due_diligence_level: "SIMPLIFIED").count
    assert_equal simplified_count, results["a1203"].to_i

    # a1203D is count of REINFORCED due diligence clients
    reinforced_count = @organization.clients.kept
                                    .where(due_diligence_level: "REINFORCED").count
    assert_equal reinforced_count, results["a1203D"].to_i
  end

  test "calculates clients by professional category" do
    results = @engine.extended_client_statistics

    # a11301 is count of REAL_ESTATE professional category clients
    real_estate_count = @organization.clients.kept
                                     .where(professional_category: "REAL_ESTATE").count
    assert_equal real_estate_count, results["a11301"].to_i

    # a11302 is count of FINANCIAL_SERVICES professional category clients
    financial_count = @organization.clients.kept
                                   .where(professional_category: "FINANCIAL_SERVICES").count
    assert_equal financial_count, results["a11302"].to_i
  end

  test "calculates source verification counts" do
    results = @engine.extended_client_statistics

    # Count clients with verified source of funds
    sof_verified = @organization.clients.kept
                                .where(source_of_funds_verified: true).count
    assert_equal sof_verified, results["a1204S"].to_i

    # Count clients with verified source of wealth
    sow_verified = @organization.clients.kept
                                .where(source_of_wealth_verified: true).count
    assert_equal sow_verified, results["a14001"].to_i
  end
end
