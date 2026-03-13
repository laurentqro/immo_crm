# frozen_string_literal: true

module Api
  module V1
    class ManagedPropertiesController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_managed_property, only: [:show, :update, :destroy]

      # GET /api/v1/managed_properties
      def index
        properties = policy_scope(ManagedProperty).includes(:client)
        properties = properties.where(property_type: params[:property_type]) if params[:property_type].present?

        if params[:status] == "active"
          properties = properties.active
        elsif params[:status] == "ended"
          properties = properties.ended
        end

        properties = properties.order(management_start_date: :desc)

        render json: properties.as_json(include: { client: { only: [:id, :name] } })
      end

      # GET /api/v1/managed_properties/:id
      def show
        authorize @managed_property
        render json: @managed_property.as_json(include: { client: { only: [:id, :name] } })
      end

      # POST /api/v1/managed_properties
      def create
        property = current_organization.managed_properties.build(managed_property_params)
        authorize property

        if property.save
          render json: property.as_json, status: :created
        else
          render json: { errors: property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/managed_properties/:id
      def update
        authorize @managed_property

        if @managed_property.update(managed_property_params)
          render json: @managed_property.as_json
        else
          render json: { errors: @managed_property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/managed_properties/:id
      def destroy
        authorize @managed_property
        @managed_property.destroy
        head :no_content
      end

      private

      def set_managed_property
        @managed_property = policy_scope(ManagedProperty).find_by(id: params[:id])
        render json: { error: "Managed property not found" }, status: :not_found unless @managed_property
      end

      def managed_property_params
        params.require(:managed_property).permit(
          ManagedPropertyPolicy.new(pundit_user, ManagedProperty).permitted_attributes
        )
      end
    end
  end
end
