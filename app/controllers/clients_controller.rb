# frozen_string_literal: true

# CRUD controller for Client management.
# Handles natural persons (NATURAL_PERSON) and legal entities (LEGAL_ENTITY, including trusts).
class ClientsController < ApplicationController
  include OrganizationScoped

  before_action :set_client, only: [:show, :edit, :update, :destroy]

  def index
    @clients = policy_scope(Client).includes(:beneficial_owners, :trustees)
    @clients = @clients.where(client_type: params[:client_type]) if params[:client_type].present?
    @clients = @clients.where(risk_level: params[:risk_level]) if params[:risk_level].present?
    @clients = @clients.search(params[:q]) if params[:q].present?
    @clients = @clients.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    authorize @client
  end

  def new
    @client = current_organization.clients.build
    authorize @client
  end

  def edit
    authorize @client
  end

  def create
    @client = current_organization.clients.build(client_params)
    authorize @client

    respond_to do |format|
      if @client.save
        format.html { redirect_to @client, notice: "Client was successfully created." }
        format.turbo_stream { redirect_to @client, notice: "Client was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @client

    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to @client, notice: "Client was successfully updated." }
        format.turbo_stream { redirect_to @client, notice: "Client was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @client
    @client.discard

    respond_to do |format|
      format.html { redirect_to clients_path, notice: "Client was successfully deleted." }
      format.turbo_stream
    end
  end

  private

  def set_client
    @client = policy_scope(Client.with_discarded).includes(:trustees, :beneficial_owners).find_by(id: params[:id])
    render_not_found unless @client
  end

  def client_params
    params.expect(client: policy(@client || Client).permitted_attributes)
  end
end
