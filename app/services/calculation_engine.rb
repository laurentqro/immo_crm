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
      pep_transaction_statistics,
      str_statistics,
      beneficial_owner_statistics
    )
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
          submission_value.assign_attributes(
            value: value.to_s,
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
      "a1301" => clients.peps.count,
      "a1401" => clients.high_risk.count
    }
  end

  def client_nationality_breakdown
    result = {}
    clients = organization.clients.kept

    # Group by nationality and count
    clients.group(:nationality).count.each do |nationality, count|
      next if nationality.blank?

      # Sanitize nationality to ISO 3166-1 alpha-2 format (2 uppercase letters only)
      safe_nationality = nationality.to_s.upcase.gsub(/[^A-Z]/, "")
      next if safe_nationality.blank? || safe_nationality.length != 2

      result["a1103_#{safe_nationality}"] = count
    end

    result
  end

  # === Transaction Statistics ===

  def transaction_statistics
    txns = year_transactions

    {
      "a2101B" => txns.count,
      "a2102" => txns.purchases.count,
      "a2103" => txns.sales.count,
      "a2104" => txns.rentals.count
    }
  end

  def transaction_values
    txns = year_transactions

    {
      "a2104B" => txns.sum(:transaction_value),
      "a2105" => txns.purchases.sum(:transaction_value),
      "a2106" => txns.sales.sum(:transaction_value),
      "a2107" => txns.rentals.sum(:transaction_value)
    }
  end

  # === Payment Method Statistics ===

  def payment_method_statistics
    txns = year_transactions
    cash_txns = txns.where(payment_method: %w[CASH MIXED])
    crypto_txns = txns.where(payment_method: "CRYPTO")

    {
      "a2201" => cash_txns.count,
      "a2202" => cash_txns.sum(:cash_amount),
      "a2301" => crypto_txns.count,
      "a2302" => crypto_txns.sum(:transaction_value)
    }
  end

  # === PEP Transaction Statistics ===

  def pep_transaction_statistics
    # Use subquery instead of pluck to avoid loading IDs into memory
    pep_txns = year_transactions.where(
      client_id: organization.clients.kept.peps.select(:id)
    )

    {
      "a2401" => pep_txns.count
    }
  end

  # === STR Statistics ===

  def str_statistics
    year_start = Date.new(year, 1, 1)
    year_end = Date.new(year, 12, 31)

    str_count = organization.str_reports.kept
                            .where(report_date: year_start..year_end)
                            .count

    { "a3101" => str_count }
  end

  # === Beneficial Owner Statistics ===

  def beneficial_owner_statistics
    legal_entity_bos = organization.clients.kept.legal_entities
                                   .joins(:beneficial_owners)
                                   .count

    trust_bos = organization.clients.kept.trusts
                            .joins(:beneficial_owners)
                            .count

    pep_bos = BeneficialOwner.joins(:client)
                             .where(clients: { organization_id: organization.id })
                             .where(is_pep: true)
                             .count

    {
      "a1501" => legal_entity_bos + trust_bos,
      "a1502" => pep_bos
    }
  end

  # === Helpers ===

  def year_transactions
    organization.transactions.kept.for_year(year)
  end
end
