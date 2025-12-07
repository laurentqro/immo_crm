# frozen_string_literal: true

# CRUD controller for Submission management.
# Handles annual AMSF submission workflow and XBRL downloads.
class SubmissionsController < ApplicationController
  include OrganizationScoped

  before_action :set_submission, only: [:show, :edit, :update, :destroy, :download, :reopen]

  def index
    @submissions = policy_scope(Submission)
    @submissions = @submissions.for_year(params[:year].to_i) if params[:year].present?
    @submissions = @submissions.where(status: params[:status]) if params[:status].present?
    @submissions = @submissions.order(year: :desc)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @submission
    @organization = current_organization
    @manifest = Xbrl::ElementManifest.new(@submission)

    respond_to do |format|
      format.html
      format.xml
      format.md { render markdown: @submission }
    end
  end

  def new
    @submission = current_organization.submissions.build(year: Date.current.year)
    authorize @submission
  end

  def edit
    authorize @submission
  end

  def create
    year = submission_params[:year].to_i
    existing = current_organization.submissions.find_by(year: year)

    if existing
      # Resume existing submission - redirect to review page
      redirect_to submission_review_path(existing)
      return
    end

    @submission = current_organization.submissions.build(submission_params)
    authorize @submission

    respond_to do |format|
      if @submission.save
        format.html do
          redirect_to submission_review_path(@submission),
                      notice: "Submission started for #{@submission.year}."
        end
        format.turbo_stream { flash.now[:notice] = "Submission started for #{@submission.year}." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @submission

    respond_to do |format|
      if handle_status_transition || @submission.update(submission_params)
        format.html { redirect_to @submission, notice: "Submission was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "Submission was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @submission

    if @submission.completed?
      respond_to do |format|
        format.html do
          redirect_to submissions_path,
                      alert: "Cannot delete a completed submission.",
                      status: :unprocessable_entity
        end
        format.turbo_stream { head :unprocessable_entity }
      end
      return
    end

    @submission.destroy

    respond_to do |format|
      format.html { redirect_to submissions_path, notice: "Submission was successfully deleted." }
      format.turbo_stream { flash.now[:notice] = "Submission was successfully deleted." }
    end
  end

  # FR-025: Reopen a completed submission for editing
  def reopen
    authorize @submission, :reopen?

    @submission.reopen!

    respond_to do |format|
      format.html do
        redirect_to submission_submission_step_path(@submission, step: 1),
                    notice: "Submission reopened for editing."
      end
      format.turbo_stream { flash.now[:notice] = "Submission reopened for editing." }
    end
  rescue Submission::InvalidTransition => e
    respond_to do |format|
      format.html do
        redirect_to @submission, alert: "Cannot reopen: #{e.message}"
      end
      format.turbo_stream { head :unprocessable_entity }
    end
  end

  def download
    # Mark as unvalidated download before authorization so downloadable? returns true
    if params[:unvalidated].present? && !@submission.validated? && !@submission.completed?
      @submission.downloaded_unvalidated = true
    end

    authorize @submission, :download?

    # Persist the unvalidated download flag if applicable
    @submission.save! if @submission.downloaded_unvalidated_changed?

    # Log the download
    create_download_audit_log

    # Generate and send XBRL
    renderer = SubmissionRenderer.new(@submission)
    xbrl_content = renderer.to_xbrl
    filename = renderer.suggested_filename

    send_data xbrl_content,
              filename: filename,
              type: "application/xml",
              disposition: "attachment"
  end

  private

  def set_submission
    @submission = policy_scope(Submission).find_by(id: params[:id])
    render_not_found unless @submission
  end

  def submission_params
    params.expect(submission: [:year, :taxonomy_version, :status])
  end

  def handle_status_transition
    return false unless params.dig(:submission, :status).present?

    new_status = params[:submission][:status]
    case new_status
    when "in_review"
      @submission.start_review! if @submission.may_start_review?
    when "validated"
      @submission.validate_submission! if @submission.may_validate_submission?
    when "completed"
      @submission.complete! if @submission.may_complete?
    when "draft"
      @submission.reject! if @submission.may_reject?
    else
      return false
    end
    true
  rescue Submission::InvalidTransition
    false
  end

  def create_download_audit_log
    return unless defined?(AuditLog)

    AuditLog.create!(
      auditable: @submission,
      user: Current.user,
      organization: current_organization,
      action: "download"
    )
  end
end
