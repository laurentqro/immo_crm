# frozen_string_literal: true

module Api
  module V1
    class SubmissionsController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_submission, only: [:show, :update, :destroy, :complete, :validate, :download]

      # GET /api/v1/submissions
      def index
        submissions = current_organization.submissions.recent_first
        render json: submissions.as_json
      end

      # GET /api/v1/submissions/:id
      def show
        render json: serialize_submission(@submission)
      end

      # POST /api/v1/submissions
      def create
        submission = current_organization.submissions.build(submission_params)

        if submission.save
          render json: submission.as_json, status: :created
        else
          render json: { errors: submission.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/submissions/:id
      def update
        if @submission.update(submission_params)
          render json: @submission.as_json
        else
          render json: { errors: @submission.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/submissions/:id
      def destroy
        @submission.destroy
        head :no_content
      end

      # POST /api/v1/submissions/:id/complete
      def complete
        result = Submissions::Complete.call(submission: @submission)

        if result.success?
          render json: serialize_submission(result.record)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/submissions/:id/validate
      def validate
        result = Submissions::Validate.call(submission: @submission)
        render json: result.record || { valid: result.success?, errors: result.errors }
      end

      # GET /api/v1/submissions/:id/download
      def download
        survey = Survey.new(organization: current_organization, year: @submission.year)
        xml_content = survey.to_xbrl
        send_data xml_content, filename: "amsf_survey_#{@submission.year}.xml", type: "application/xml"
      end

      # GET /api/v1/submissions/preview?year=2025
      def preview
        year = params[:year]&.to_i || Date.current.year
        result = Submissions::Generate.call(organization: current_organization, year: year)

        if result.success?
          render json: result.record
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_submission
        @submission = current_organization.submissions.find_by(id: params[:id])
        render json: { error: "Submission not found" }, status: :not_found unless @submission
      end

      def submission_params
        params.require(:submission).permit(:year, :taxonomy_version)
      end

      def serialize_submission(submission)
        submission.as_json.merge(
          "editable" => submission.editable?,
          "merged_answers" => submission.merged_answers
        )
      end
    end
  end
end
