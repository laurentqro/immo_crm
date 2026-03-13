# frozen_string_literal: true

module Api
  module V1
    class TrainingsController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_training, only: [:show, :update, :destroy]

      # GET /api/v1/trainings
      def index
        trainings = policy_scope(Training)
        trainings = trainings.by_type(params[:training_type]) if params[:training_type].present?
        trainings = trainings.for_year(params[:year].to_i) if params[:year].present?
        trainings = trainings.recent

        render json: trainings.as_json
      end

      # GET /api/v1/trainings/:id
      def show
        authorize @training
        render json: @training.as_json
      end

      # POST /api/v1/trainings
      def create
        training = current_organization.trainings.build(training_params)
        authorize training

        if training.save
          render json: training.as_json, status: :created
        else
          render json: { errors: training.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/trainings/:id
      def update
        authorize @training

        if @training.update(training_params)
          render json: @training.as_json
        else
          render json: { errors: @training.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/trainings/:id
      def destroy
        authorize @training
        @training.destroy
        head :no_content
      end

      private

      def set_training
        @training = policy_scope(Training).find_by(id: params[:id])
        render json: { error: "Training not found" }, status: :not_found unless @training
      end

      def training_params
        params.require(:training).permit(
          TrainingPolicy.new(pundit_user, Training).permitted_attributes
        )
      end
    end
  end
end
