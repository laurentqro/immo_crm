# frozen_string_literal: true

module Api
  module V1
    class ClientsController < Api::BaseController
      include ApiOrganizationScoped

      before_action :set_client, only: [:show, :update, :destroy, :assess_risk]

      # GET /api/v1/clients
      def index
        clients = policy_scope(Client).includes(:beneficial_owners)
        clients = clients.where(client_type: params[:client_type]) if params[:client_type].present?
        clients = clients.where(risk_level: params[:risk_level]) if params[:risk_level].present?
        clients = clients.search(params[:q]) if params[:q].present?
        clients = clients.order(created_at: :desc)

        render json: clients.map { |c| serialize_client(c) }
      end

      # GET /api/v1/clients/:id
      def show
        authorize @client
        render json: serialize_client(@client, include_owners: true)
      end

      # POST /api/v1/clients
      def create
        result = Clients::Create.call(
          organization: current_organization,
          params: client_params
        )

        if result.success?
          render json: serialize_client(result.record), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/clients/:id
      def update
        authorize @client

        result = Clients::Update.call(client: @client, params: client_params)

        if result.success?
          render json: serialize_client(result.record)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/clients/:id
      def destroy
        authorize @client
        @client.discard
        head :no_content
      end

      # POST /api/v1/clients/onboard
      def onboard
        result = Clients::Onboard.call(
          organization: current_organization,
          client_params: client_params,
          beneficial_owners: params[:beneficial_owners]&.map { |bo| bo.permit(*beneficial_owner_attrs) } || []
        )

        if result.success?
          render json: serialize_client(result.record, include_owners: true), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/clients/:id/assess_risk
      def assess_risk
        authorize @client, :show?

        result = Clients::AssessRisk.call(client: @client)
        render json: result.record
      end

      private

      def set_client
        @client = policy_scope(Client.with_discarded).find_by(id: params[:id])
        render json: { error: "Client not found" }, status: :not_found unless @client
      end

      def client_params
        params.require(:client).permit(ClientPolicy.new(pundit_user, Client).permitted_attributes)
      end

      def beneficial_owner_attrs
        BeneficialOwnerPolicy.new(pundit_user, BeneficialOwner).permitted_attributes
      end

      def serialize_client(client, include_owners: false)
        data = client.as_json(except: [:deleted_at])
        if include_owners && client.can_have_beneficial_owners?
          data["beneficial_owners"] = client.beneficial_owners.as_json
        end
        data
      end
    end
  end
end
