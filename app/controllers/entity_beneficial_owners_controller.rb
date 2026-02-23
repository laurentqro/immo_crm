# frozen_string_literal: true

# CRUD controller for the reporting entity's own beneficial owners.
# These describe who owns the real estate agency itself (not client BOs).
class EntityBeneficialOwnersController < ApplicationController
  include OrganizationScoped

  def index
    authorize EntityBeneficialOwner
    @entity_beneficial_owners = policy_scope(EntityBeneficialOwner).order(:name)
    @entity_beneficial_owner = current_organization.entity_beneficial_owners.build
  end

  def create
    @entity_beneficial_owner = current_organization.entity_beneficial_owners.build(entity_beneficial_owner_params)
    authorize @entity_beneficial_owner

    if @entity_beneficial_owner.save
      redirect_to entity_beneficial_owners_path, notice: "Beneficial owner added."
    else
      @entity_beneficial_owners = policy_scope(EntityBeneficialOwner).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @entity_beneficial_owner = policy_scope(EntityBeneficialOwner).find_by(id: params[:id])
    return render_not_found unless @entity_beneficial_owner

    authorize @entity_beneficial_owner
    @entity_beneficial_owner.destroy
    redirect_to entity_beneficial_owners_path, notice: "Beneficial owner removed."
  end

  private

  def entity_beneficial_owner_params
    params.expect(entity_beneficial_owner: [:name, :nationality])
  end
end
