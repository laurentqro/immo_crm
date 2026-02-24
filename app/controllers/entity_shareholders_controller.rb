# frozen_string_literal: true

# CRUD controller for the reporting entity's own shareholders (25%+ ownership).
# These describe who holds shares in the real estate agency itself (not client shareholders).
class EntityShareholdersController < ApplicationController
  include OrganizationScoped

  def index
    authorize EntityShareholder
    @entity_shareholders = policy_scope(EntityShareholder).order(:name)
    @entity_shareholder = current_organization.entity_shareholders.build
  end

  def create
    @entity_shareholder = current_organization.entity_shareholders.build(entity_shareholder_params)
    authorize @entity_shareholder

    if @entity_shareholder.save
      redirect_to entity_shareholders_path, notice: "Shareholder added."
    else
      @entity_shareholders = policy_scope(EntityShareholder).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @entity_shareholder = policy_scope(EntityShareholder).find_by(id: params[:id])
    return render_not_found unless @entity_shareholder

    authorize @entity_shareholder
    @entity_shareholder.destroy
    redirect_to entity_shareholders_path, notice: "Shareholder removed."
  end

  private

  def entity_shareholder_params
    params.expect(entity_shareholder: [:name, :nationality])
  end
end
