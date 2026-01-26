class SurveyReviewsController < ApplicationController
  before_action :set_submission

  def show
    @survey = Survey.new(organization: current_organization, year: @submission.year)
  end

  def complete
    @submission.complete!
    redirect_to submission_path(@submission), notice: "Submission completed successfully."
  end

  private

  def set_submission
    @submission = current_organization.submissions.find(params[:submission_id])
  end
end
