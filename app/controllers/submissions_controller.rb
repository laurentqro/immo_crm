# frozen_string_literal: true

class SubmissionsController < ApplicationController
  before_action :set_submission, only: [:show, :edit, :update, :destroy, :download, :review, :complete]

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
    # TODO: Generate and send XBRL file
    head :not_implemented
  end

  # GET /submissions/:id/review
  def review
    authorize @submission
    @survey = Survey.new(organization: current_organization, year: @submission.year)
  end

  # POST /submissions/:id/complete
  def complete
    @submission.complete!
    redirect_to submission_path(@submission), notice: "Submission completed successfully."
  end

  private

  def set_submission
    @submission = current_organization.submissions.find(params[:id])
  end

  def submission_params
    params.require(:submission).permit(:year, :taxonomy_version)
  end
end
