# frozen_string_literal: true

# CalculationEngine calculates aggregate statistics from CRM data
# for AMSF annual submissions.
#
# Each calculation maps to an XBRL element in the taxonomy.
# Results can be stored as SubmissionValues for the submission.
#
class CalculationEngine
  attr_reader :submission, :organization, :year

  def initialize(submission)
    @submission = submission
    @organization = submission.organization
    @year = submission.year
  end

  # Calculate all aggregate values for the submission
  # Returns a Hash mapping XBRL element names to values
  def calculate_all
    {}.merge(
      client_statistics,
      client_nationality_breakdown,
      transaction_statistics,
      transaction_values,
      payment_method_statistics,
      str_statistics,
      beneficial_owner_statistics
    )
    # Note: pep_transaction_statistics removed - a2401 not in AMSF taxonomy
  end

  # Persist calculated values to submission_values table
  # Idempotent - updates existing values or creates new ones
  # Wrapped in transaction for data integrity
  def populate_submission_values!
    submission.transaction do
      # Populate calculated values from CRM data
      calculate_all.each do |element_name, value|
        submission_value = submission.submission_values.find_or_initialize_by(
          element_name: element_name
        )

        # Only update if not overridden by user
        unless submission_value.persisted? && submission_value.overridden?
          # Serialize hashes as JSON for dimensional elements like a1103
          serialized_value = value.is_a?(Hash) ? value.to_json : value.to_s

          submission_value.assign_attributes(
            value: serialized_value,
            source: "calculated"
          )
          submission_value.save!
        end
      end

      # Populate settings-based values (policies, entity info)
      populate_settings_values!
    end
  end

  # Copy organization settings with XBRL mappings to submission values
  def populate_settings_values!
    organization.settings.where.not(xbrl_element: [nil, ""]).find_each do |setting|
      submission_value = submission.submission_values.find_or_initialize_by(
        element_name: setting.xbrl_element
      )

      # Only update if not already confirmed by user
      unless submission_value.persisted? && submission_value.confirmed?
        submission_value.assign_attributes(
          value: setting.value.to_s,
          source: "from_settings"
        )
        submission_value.save!
      end
    end
  end

  private

  # === Client Statistics ===

  def client_statistics
    clients = organization.clients.kept

    {
      "a1101" => clients.count,
      "a1102" => clients.natural_persons.count,
      "a11502B" => clients.legal_entities.count,
      "a11802B" => clients.trusts.count,
      "a12002B" => clients.peps.count,
      "a1401" => clients.high_risk.count
    }
  end

  def client_nationality_breakdown
    result = {}
    clients = organization.clients.kept

    # Group by nationality and count - return nested hash for dimensional contexts
    country_counts = {}
    clients.group(:nationality).count.each do |nationality, count|
      next if nationality.blank?

      # Sanitize nationality to ISO 3166-1 alpha-2 format (2 uppercase letters only)
      safe_nationality = nationality.to_s.upcase.gsub(/[^A-Z]/, "")
      next if safe_nationality.blank? || safe_nationality.length != 2

      country_counts[safe_nationality] = count
    end

    # Return single element with nested hash for XbrlGenerator to create dimensional contexts
    result["a1103"] = country_counts if country_counts.any?

    result
  end

  # === Transaction Statistics ===

  def transaction_statistics
    txns = year_transactions

    # Note: a2101B is a Oui/Non question ("Did you have transactions?"), not a count
    # There is no single "total transactions" integer element in the taxonomy
    # a2108B is the correct element for rental count (a2107B is Oui/Non)
    {
      "a2102B" => txns.purchases.count,
      "a2105B" => txns.sales.count,
      "a2108B" => txns.rentals.count
    }
  end

  def transaction_values
    txns = year_transactions

    # a2109B is the correct element for total transaction value (a2104B is Oui/Non)
    {
      "a2109B" => txns.sum(:transaction_value),
      "a2102BB" => txns.purchases.sum(:transaction_value),
      "a2105BB" => txns.sales.sum(:transaction_value)
      # Note: Rental value has no dedicated monetary element in taxonomy
    }
  end

  # === Payment Method Statistics ===

  def payment_method_statistics
    txns = year_transactions
    cash_txns = txns.where(payment_method: %w[CASH MIXED])
    crypto_txns = txns.where(payment_method: "CRYPTO")

    # a2202 and a2501A are Oui/Non questions, not counts/values
    # a2203 is string type (free text), we store the count as string
    {
      "a2203" => cash_txns.count.to_s,
      "a2202" => cash_txns.exists? ? "Oui" : "Non",
      "a2501A" => crypto_txns.exists? ? "Oui" : "Non"
    }
  end

  # === STR Statistics ===

  def str_statistics
    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)

    str_count = organization.str_reports.kept
      .where(report_date: year_start..year_end)
      .count

    # a3102 is the integer count element (a3101 is Oui/Non question)
    {"a3102" => str_count}
  end

  # === Beneficial Owner Statistics ===

  def beneficial_owner_statistics
    # Count beneficial owners starting from BeneficialOwner for clarity
    base_query = BeneficialOwner.joins(:client)
      .merge(Client.kept)
      .where(clients: {organization_id: organization.id})

    # Single query with grouping for PM and TRUST types
    counts_by_type = base_query
      .where(clients: {client_type: %w[PM TRUST]})
      .group("clients.client_type")
      .count

    pep_bos = base_query.where(is_pep: true).count

    {
      "a1501" => counts_by_type.values.sum,
      "a1502B" => pep_bos
    }
  end

  # === Helpers ===

  def year_transactions
    organization.transactions.kept.for_year(year)
  end
end
