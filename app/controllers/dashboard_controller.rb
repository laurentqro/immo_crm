# frozen_string_literal: true

# Main dashboard for authenticated users with an organization.
# Displays CRM stats, recent activity, and submission status.
class DashboardController < ApplicationController
  include OrganizationScoped

  def show
    # Submission year = reporting period (previous calendar year)
    # e.g., in 2026, we submit data for 2025
    @year = params[:year]&.to_i || (Date.current.year - 1)
    @stats = calculate_stats
    @recent_transactions = fetch_recent_transactions
    @submission_status = fetch_submission_status
  end

  private

  def calculate_stats
    # TODO: These will query real data once Client/Transaction models exist
    {
      clients_count: client_count,
      transactions_count: transaction_count,
      transactions_value: transaction_value,
      strs_count: str_count
    }
  end

  def client_count
    return 0 unless defined?(Client) && Client.table_exists?

    organization_scope(Client).count
  end

  def transaction_count
    return 0 unless defined?(Transaction) && Transaction.table_exists?

    organization_scope(Transaction)
      .where("EXTRACT(YEAR FROM transaction_date) = ?", @year)
      .count
  end

  def transaction_value
    return 0 unless defined?(Transaction) && Transaction.table_exists?

    organization_scope(Transaction)
      .where("EXTRACT(YEAR FROM transaction_date) = ?", @year)
      .sum(:transaction_value)
  end

  def str_count
    return 0 unless defined?(StrReport) && StrReport.table_exists?

    organization_scope(StrReport)
      .where("EXTRACT(YEAR FROM report_date) = ?", @year)
      .count
  end

  def fetch_recent_transactions
    return [] unless defined?(Transaction) && Transaction.table_exists?

    policy_scope(Transaction)
      .includes(:client)
      .order(transaction_date: :desc)
      .limit(5)
  end

  def fetch_submission_status
    return { status: :not_started, year: @year } unless defined?(Submission) && Submission.table_exists?

    submission = organization_scope(Submission).find_by(year: @year)

    if submission
      { status: submission.status.to_sym, year: @year, submission: submission }
    else
      { status: :not_started, year: @year }
    end
  end
end
