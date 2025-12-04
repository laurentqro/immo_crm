# frozen_string_literal: true

# Nested controller for BeneficialOwner management.
# Beneficial owners belong to legal entity (PM) or trust clients.
# Uses shallow routing: collection actions nest under clients, member actions are shallow.
class BeneficialOwnersController < ApplicationController
  include OrganizationScoped

  before_action :set_client, only: [:index, :new, :create]
  before_action :set_beneficial_owner, only: [:edit, :update, :destroy]

  def index
    authorize BeneficialOwner
    @beneficial_owners = @client.beneficial_owners
  end

  def new
    @beneficial_owner = @client.beneficial_owners.build
    authorize @beneficial_owner
  end

  def edit
    authorize @beneficial_owner
  end

  def create
    @beneficial_owner = @client.beneficial_owners.build(beneficial_owner_params)
    authorize @beneficial_owner

    respond_to do |format|
      if @beneficial_owner.save
        format.html { redirect_to @client, notice: "Beneficial owner was successfully added." }
        format.turbo_stream { flash.now[:notice] = "Beneficial owner was successfully added." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @beneficial_owner

    respond_to do |format|
      if @beneficial_owner.update(beneficial_owner_params)
        format.html { redirect_to @client, notice: "Beneficial owner was successfully updated." }
        format.turbo_stream { flash.now[:notice] = "Beneficial owner was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :form_errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @beneficial_owner
    @beneficial_owner.destroy

    respond_to do |format|
      format.html { redirect_to @client, notice: "Beneficial owner was successfully removed." }
      format.turbo_stream { flash.now[:notice] = "Beneficial owner was successfully removed." }
    end
  end

  private

  # For collection actions (index, new, create) - client_id is in params
  def set_client
    @client = policy_scope(Client).find_by(id: params[:client_id])
    return render_not_found unless @client

    render_not_found unless @client.can_have_beneficial_owners?
  end

  # For member actions (edit, update, destroy) - shallow route, find owner first then get client
  def set_beneficial_owner
    @beneficial_owner = BeneficialOwner.find_by(id: params[:id])
    return render_not_found unless @beneficial_owner

    # Get client and verify authorization
    @client = @beneficial_owner.client
    return render_not_found unless policy_scope(Client).exists?(id: @client.id)

    render_not_found unless @client.can_have_beneficial_owners?
  end

  def beneficial_owner_params
    params.expect(beneficial_owner: policy(@beneficial_owner || BeneficialOwner).permitted_attributes)
  end
end
