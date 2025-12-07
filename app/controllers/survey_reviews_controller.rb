# frozen_string_literal: true

# Controller for single-page AMSF survey review.
# Displays all survey elements organized by official AMSF questionnaire sections.
# Part of 015-amsf-survey-review feature - replaces 7-step wizard with single review page.
class SurveyReviewsController < ApplicationController
  include OrganizationScoped

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized

  before_action :set_submission
  before_action :authorize_submission
  before_action :authorize_complete, only: [:complete]
  before_action :ensure_values_calculated, only: [:show]

  # GET /submissions/:submission_id/review
  # Displays all AMSF survey elements on a single scrollable page
  def show
    @sections = build_sections_with_elements
    @organization = current_organization
  end

  # POST /submissions/:submission_id/review/complete
  # Transitions submission to completed status
  # Authorization via authorize_complete ensures only validated submissions can be completed
  def complete
    @submission.complete!

    respond_to do |format|
      format.html { redirect_to submission_path(@submission), notice: "Submission completed successfully." }
      format.turbo_stream { flash.now[:notice] = "Submission completed successfully." }
    end
  rescue Submission::InvalidTransition => e
    respond_to do |format|
      format.html { redirect_to submission_review_path(@submission), alert: "Cannot complete: #{e.message}" }
      format.turbo_stream { head :unprocessable_entity }
    end
  end

  private

  # T020: Set submission from params, scoped to current organization
  # Eager-load submission_values to avoid extra query in ElementManifest
  def set_submission
    @submission = policy_scope(Submission)
                    .includes(:submission_values)
                    .find_by(id: params[:submission_id])
    render_not_found unless @submission
  end

  # T020: Authorize access to submission
  def authorize_submission
    authorize @submission, :show?
  end

  # T020: Authorize completion - requires validated state per SubmissionPolicy#complete?
  def authorize_complete
    authorize @submission, :complete?
  end

  # Handle Pundit authorization failures
  def handle_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    action = exception.query

    respond_to do |format|
      format.html do
        flash[:alert] = t("pundit.#{policy_name}.#{action}", default: t("unauthorized"))
        redirect_back(fallback_location: submission_review_path(@submission))
      end
      format.turbo_stream { head :forbidden }
      format.json { head :forbidden }
    end
  end

  # T021: Ensure submission values are calculated before displaying
  # Draft submissions always recalculate to reflect latest CRM data.
  # Completed submissions are frozen as point-in-time snapshots for audit.
  def ensure_values_calculated
    return if @submission.completed? && @submission.submission_values.any?

    # Recalculate for drafts or if no values exist
    CalculationEngine.new(@submission).populate_submission_values!
    @submission.reload
  rescue StandardError => e
    # Log error but continue - show page with existing/partial values
    Rails.logger.error("Failed to calculate submission values: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    flash.now[:alert] = "Some values could not be calculated. Please try refreshing the page."
  end

  # T022: Build sections with their elements for display
  # Returns array of sections with elements populated from manifest
  # Excludes sections with no elements (no values to display)
  def build_sections_with_elements
    manifest = Xbrl::ElementManifest.new(@submission)

    Xbrl::Survey.sections.filter_map do |section|
      elements = section[:elements].filter_map do |element_name|
        manifest.element_with_value(element_name)
      end

      # Skip sections with no elements
      next if elements.empty?

      {
        id: section[:id],
        title: section[:title],
        elements: elements,
        has_review_flags: elements.any?(&:needs_review?)
      }
    end
  end
end
