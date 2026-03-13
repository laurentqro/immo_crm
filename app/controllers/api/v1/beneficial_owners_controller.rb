# frozen_string_literal: true

module Api
  module V1
    class BeneficialOwnersController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_client, only: [:index, :create]
      before_action :set_beneficial_owner, only: [:show, :update, :destroy]

      # GET /api/v1/clients/:client_id/beneficial_owners
      def index
        authorize BeneficialOwner
        render json: @client.beneficial_owners.as_json
      end

      # GET /api/v1/beneficial_owners/:id
      def show
        authorize @beneficial_owner
        render json: @beneficial_owner.as_json
      end

      # POST /api/v1/clients/:client_id/beneficial_owners
      def create
        owner = @client.beneficial_owners.build(beneficial_owner_params)
        authorize owner

        if owner.save
          render json: owner.as_json, status: :created
        else
          render json: { errors: owner.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/beneficial_owners/:id
      def update
        authorize @beneficial_owner

        if @beneficial_owner.update(beneficial_owner_params)
          render json: @beneficial_owner.as_json
        else
          render json: { errors: @beneficial_owner.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/beneficial_owners/:id
      def destroy
        authorize @beneficial_owner
        @beneficial_owner.destroy
        head :no_content
      end

      private

      def set_client
        @client = policy_scope(Client).find_by(id: params[:client_id])
        return render json: { error: "Client not found" }, status: :not_found unless @client
        return render json: { error: "Client cannot have beneficial owners" }, status: :unprocessable_entity unless @client.can_have_beneficial_owners?
      end

      def set_beneficial_owner
        @beneficial_owner = BeneficialOwner.find_by(id: params[:id])
        return render json: { error: "Beneficial owner not found" }, status: :not_found unless @beneficial_owner

        @client = @beneficial_owner.client
        return render json: { error: "Not authorized" }, status: :not_found unless policy_scope(Client).exists?(id: @client.id)
      end

      def beneficial_owner_params
        params.require(:beneficial_owner).permit(
          BeneficialOwnerPolicy.new(pundit_user, BeneficialOwner).permitted_attributes
        )
      end
    end
  end
end
