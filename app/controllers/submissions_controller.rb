# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:show, :edit, :update, :destroy, :download, :review, :complete, :validate]
  before_action :set_survey, only: [:review, :complete, :validate]

  def index
    @submissions = current_organization.submissions.recent_first
  end

  def show
  end

  def new
    @submission = current_organization.submissions.build
  end

  def create
    @submission = current_organization.submissions.build(submission_params)

    if @submission.save
      redirect_to submission_path(@submission), notice: "Submission created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @submission.update(submission_params)
      redirect_to submission_path(@submission), notice: "Submission updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @submission.destroy
    redirect_to submissions_path, notice: "Submission deleted."
  end

  def download
    survey = Survey.new(organization: current_organization, year: @submission.year)
    xml_content = survey.to_xbrl

    filename = "amsf_survey_#{Time.current.strftime('%Y_%m_%d_%H%M%S')}.xml"

    send_data xml_content,
      filename: filename,
      type: "application/xml",
      disposition: "attachment"
  end

  def review
    authorize @submission
  end

  def complete
    authorize @submission

    unless @submission.validate_xbrl
      render :review, status: :unprocessable_entity
      return
    end

    @submission.complete!
    redirect_to submission_path(@submission), notice: "Submission completed successfully."
  end

  def validate
    authorize @submission

    if @submission.validate_xbrl
      flash.now[:notice] = "XBRL validation passed! Your submission is ready to complete."
    else
      Rails.logger.info("XBRL validation failed with #{@submission.errors[:xbrl].count} errors: #{@submission.errors[:xbrl].first(3)}")
    end

    render :review
  end

  private

  def set_submission
    @submission = current_organization.submissions.find(params[:id])
  end

  def set_survey
    @survey = Survey.new(organization: current_organization, year: @submission.year)
  end

  def submission_params
    params.require(:submission).permit(:year, :taxonomy_version)
  end
end
